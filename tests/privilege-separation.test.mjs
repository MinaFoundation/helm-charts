// Requires Helm, Node, and Ruby's standard YAML library. No cluster is contacted.
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../', import.meta.url));
const helm = process.env.HELM_BIN || 'helm';
const treasury = 'decentralized-treasury';
const ledger = 'mina-staking-ledgers-provider';
function render(chart, values = {}, fail) {
  const defaults = chart === treasury
    ? { network: 'mainnet', 'config.treasuryOwnerContractAddress': 'TEST', 'config.minaNodeUrl': 'http://mina:3085/graphql' }
    : { minaNodeLabel: 'queryableNode=true' };
  const args = ['template', 'audit', chart];
  for (const [key, value] of Object.entries({ ...defaults, ...values })) args.push('--set-json', `${key}=${JSON.stringify(value)}`);
  const result = spawnSync(helm, args, { cwd: root, encoding: 'utf8', maxBuffer: 8 * 1024 * 1024 });
  if (fail) { assert.notEqual(result.status, 0); assert.match(result.stderr, fail); return; }
  assert.equal(result.status, 0, result.stderr);
  const parsed = spawnSync('ruby', ['-ryaml', '-rjson', '-e', 'puts JSON.generate(YAML.load_stream(STDIN.read).compact)'], { input: result.stdout, encoding: 'utf8', maxBuffer: 8 * 1024 * 1024 });
  assert.equal(parsed.status, 0, parsed.stderr);
  return JSON.parse(parsed.stdout);
}
const component = (resource) => resource.metadata.labels?.['app.kubernetes.io/component'];
const workloads = (docs) => docs.filter((d) => ['Deployment', 'Job'].includes(d.kind));
const deployment = (docs, name) => docs.find((d) => d.kind === 'Deployment' && component(d) === name);
const all = { 'config.multisigParticipantsPublicKeys': ['key1','key2','key3','key4','key5'], 'proving.enabled': true, 'proving.worker.autoscale.enabled': true, 'backoffice.enabled': true, 'proxy.enabled': true, 'tallyScheduler.enabled': true, 'tallyScheduler.sender.existingSecret': 'test-sender' };
test('Treasury gives each workload a separate identity; only scheduler receives Kubernetes token and scale role', () => {
  const docs = render(treasury, all);
  const pods = workloads(docs); const names = pods.map((d) => d.spec.template.spec.serviceAccountName);
  assert.equal(new Set(names).size, names.length);
  for (const d of pods) {
    const pod = d.spec.template.spec;
    assert.equal(pod.automountServiceAccountToken, component(d) === 'proving-scheduler');
    const sa = docs.find((s) => s.kind === 'ServiceAccount' && s.metadata.name === pod.serviceAccountName);
    assert.ok(sa); assert.equal(sa.automountServiceAccountToken, pod.automountServiceAccountToken);
  }
  const bindings = docs.filter((d) => d.kind === 'RoleBinding'); assert.equal(bindings.length, 1);
  assert.equal(bindings[0].subjects[0].name, deployment(docs, 'proving-scheduler').spec.template.spec.serviceAccountName);
  const role = docs.find((d) => d.kind === 'Role');
  assert.deepEqual(role.rules, [{ apiGroups: ['apps'], resources: ['deployments/scale'], resourceNames: [deployment(docs, 'proving-worker').metadata.name], verbs: ['get', 'patch'] }]);
});
test('Artifact service reaches a separate uncredentialed server with matching read-only PVCs and same-node affinity', () => {
  const docs = render(treasury, all); const writer = deployment(docs, 'proving-scheduler'); const server = deployment(docs, 'artifacts');
  assert.ok(!writer.spec.template.spec.containers.some((c) => c.name === 'serve-artifacts'));
  assert.deepEqual(server.spec.template.spec.containers.map((c) => c.name), ['serve-artifacts']);
  assert.equal(server.spec.template.spec.initContainers, undefined);
  for (const name of ['sqlite-data', 'proofs']) {
    const source = writer.spec.template.spec.volumes.find((v) => v.name === name).persistentVolumeClaim;
    const target = server.spec.template.spec.volumes.find((v) => v.name === name).persistentVolumeClaim;
    assert.equal(target.claimName, source.claimName); assert.equal(target.readOnly, true);
    assert.equal(server.spec.template.spec.containers[0].volumeMounts.find((m) => m.name === name).readOnly, true);
    assert.ok(docs.some((d) => d.kind === 'PersistentVolumeClaim' && d.metadata.name === source.claimName));
  }
  const term = server.spec.template.spec.affinity.podAffinity.requiredDuringSchedulingIgnoredDuringExecution[0];
  assert.equal(term.labelSelector.matchLabels['app.kubernetes.io/component'], 'proving-scheduler');
  assert.equal(term.topologyKey, 'kubernetes.io/hostname');
  assert.ok(writer.spec.template.spec.affinity.podAffinity.requiredDuringSchedulingIgnoredDuringExecution.length);
  const service = docs.find((d) => d.kind === 'Service' && d.metadata.name === writer.metadata.name);
  assert.equal(service.spec.selector['app.kubernetes.io/component'], 'artifacts');
});
test('Explicit false is preserved; autoscale rejects missing token and disabled server keeps ephemeral proofs', () => {
  render(treasury, { ...all, 'serviceAccounts.proving-scheduler.automount': false }, /autoscale requires/);
  const docs = render(treasury, { ...all, 'proving.worker.autoscale.enabled': false, 'serviceAccounts.proving-scheduler.automount': false, 'proving.scheduler.server.enabled': false });
  assert.ok(workloads(docs).every((d) => d.spec.template.spec.automountServiceAccountToken === false));
  assert.ok(!deployment(docs, 'artifacts')); assert.ok(!docs.some((d) => d.kind === 'RoleBinding'));
  assert.ok(deployment(docs, 'proving-scheduler').spec.template.spec.volumes.find((v) => v.name === 'proofs').emptyDir);
});
test('Cloud annotations are per workload and cannot be inherited by public artifact/web servers', () => {
  render(treasury, { 'serviceAccount.annotations': { 'eks.amazonaws.com/role-arn': 'shared-writer' } }, /no longer shared/);
  render(treasury, { ...all, 'serviceAccounts.artifacts.annotations': { 'eks.amazonaws.com/role-arn': 'writer' } }, /does not need cloud credentials/);
  const docs = render(treasury, { ...all, 'serviceAccounts.api.annotations': { 'eks.amazonaws.com/role-arn': 'read-role' }, 'serviceAccounts.proving-scheduler.annotations': { 'eks.amazonaws.com/role-arn': 'write-role' } });
  const annotated = docs.filter((d) => d.kind === 'ServiceAccount' && d.metadata.annotations);
  assert.deepEqual(annotated.map(component).sort(), ['api', 'proving-scheduler']);
  for (const d of workloads(docs)) {
    for (const c of [...(d.spec.template.spec.initContainers || []), ...d.spec.template.spec.containers]) {
      if (c.image.startsWith('amazon/aws-cli')) assert.equal(c.env.find((e) => e.name === 'AWS_EC2_METADATA_DISABLED').value, 'true');
    }
  }
});
test('Every CLI/proof workload and browser uses the same strict network', () => {
  for (const network of ['mainnet', 'devnet']) {
    const docs = render(treasury, { ...all, network });
    for (const name of ['api','processor','indexer','indexer-api','processor-api','proving-worker','proving-scheduler','voting-ledger-scheduler','tally-scheduler']) {
      const env = deployment(docs, name).spec.template.spec.containers.find((c) => c.name === name).env;
      assert.equal(env.find((e) => e.name === 'NETWORK').value, network, name);
      assert.ok(!env.some((e) => e.name === 'MINA_NETWORK_ID'));
    }
    for (const name of ['web','backoffice']) {
      const env = deployment(docs, name).spec.template.spec.containers[0].env;
      assert.equal(env.find((e) => e.name === 'NEXT_PUBLIC_NETWORK_ID').value, network);
    }
  }
  render(treasury, { network: 'testnet' }, /minaNetwork is required/);
  render(treasury, { network: 'mainnet', minaNetwork: 'testnet' }, /minaNetwork must be mainnet or devnet/);
  render(treasury, { network: 'mainnet', 'web.publicEnv.NEXT_PUBLIC_NETWORK_ID': 'devnet' }, /must match minaNetwork/);
  render(treasury, { 'tallyScheduler.minaNetworkId': 'devnet' }, /was removed/);
  render(treasury, { 'proving.worker.extraEnvVars': [{name:'NETWORK',value:'devnet'}] }, /must not override chart NETWORK/);
});
test('S3 namespace stays independent of the Mina signing network and has no default', () => {
  render(treasury, { network: '' }, /network is required/);
  render(treasury, { network: 'Main_Net', minaNetwork: 'mainnet' }, /network must be lowercase/);
  render(treasury, { ...all, network: 'singlenet' }, /minaNetwork is required when network \(singlenet\)/);
  const docs = render(treasury, { ...all, network: 'singlenet', minaNetwork: 'devnet' });
  for (const name of ['api', 'proving-scheduler', 'voting-ledger-scheduler', 'tally-scheduler']) {
    const env = deployment(docs, name).spec.template.spec.containers.find((c) => c.name === name).env;
    assert.equal(env.find((e) => e.name === 'NETWORK').value, 'devnet', name);
  }
  for (const name of ['web', 'backoffice']) {
    const env = deployment(docs, name).spec.template.spec.containers[0].env;
    assert.equal(env.find((e) => e.name === 'NEXT_PUBLIC_NETWORK_ID').value, 'devnet');
  }
  const syncs = workloads(docs).flatMap((d) => [...(d.spec.template.spec.initContainers || []), ...d.spec.template.spec.containers]).filter((c) => c.image.startsWith('amazon/aws-cli'));
  assert.ok(syncs.length);
  for (const c of syncs) {
    const prefix = c.env.find((e) => e.name === 'NETWORK');
    if (prefix) assert.equal(prefix.value, 'singlenet', c.name);
  }
});
test('External account mode requires explicit distinct names', () => {
  render(treasury, { 'serviceAccount.create': false }, /name is required/);
  render(treasury, { 'serviceAccounts.api.name': 'shared', 'serviceAccounts.processor.name': 'shared' }, /shared by multiple workloads/);
});
test('Ledger fetch and public server are separate; only fetch has exec role and writable PVC', () => {
  const docs = render(ledger); const deps = workloads(docs); assert.equal(deps.length, 2);
  const fetch = deps.find((d) => d.metadata.name.endsWith('-fetch')); const serve = deps.find((d) => d.metadata.name.endsWith('-serve'));
  assert.deepEqual(fetch.spec.template.spec.containers.map((c) => c.name), ['fetch']);
  assert.deepEqual(serve.spec.template.spec.containers.map((c) => c.name), ['serve']);
  assert.notEqual(fetch.spec.template.spec.serviceAccountName, serve.spec.template.spec.serviceAccountName);
  assert.equal(serve.spec.template.spec.automountServiceAccountToken, false);
  assert.equal(docs.find((d) => d.kind === 'RoleBinding').subjects[0].name, fetch.spec.template.spec.serviceAccountName);
  const volume = serve.spec.template.spec.volumes.find((v) => v.name === 'ledgers'); assert.equal(volume.persistentVolumeClaim.readOnly, true);
  assert.equal(serve.spec.template.spec.containers[0].volumeMounts.find((v) => v.name === 'ledgers').readOnly, true);
  assert.equal(docs.find((d) => d.kind === 'Service').spec.selector['app.kubernetes.io/component'], 'serve');
  assert.equal(serve.spec.template.spec.affinity.podAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels['app.kubernetes.io/component'], 'fetch');
  assert.ok(fetch.spec.template.spec.affinity.podAffinity.requiredDuringSchedulingIgnoredDuringExecution.length);
  assert.equal(fetch.spec.template.spec.serviceAccountName, 'audit-mina-staking-ledgers-provider');
  const serverAccount = docs.find((d) => d.kind === 'ServiceAccount' && d.metadata.name === serve.spec.template.spec.serviceAccountName); assert.equal(serverAccount.metadata.annotations, undefined);
});
test('Ledger honors false, enforces identity separation, and rejects single-pod storage mode', () => {
  const docs = render(ledger, { 'serviceAccount.automount': false });
  assert.ok(workloads(docs).every((d) => d.spec.template.spec.automountServiceAccountToken === false));
  render(ledger, { 'serviceAccount.name': 'shared', 'server.serviceAccountName': 'shared' }, /distinct service accounts/);
  render(ledger, { 'persistence.accessMode': 'ReadWriteOncePod' }, /require ReadWriteOnce or ReadWriteMany/);
});

test('Voting scheduler allows checkpoint shutdown and honors the configured grace period', () => {
  assert.equal(deployment(render(treasury), 'voting-ledger-scheduler').spec.template.spec.terminationGracePeriodSeconds, 1260);
  assert.equal(deployment(render(treasury, { 'votingLedgerScheduler.terminationGracePeriodSeconds': 1800 }), 'voting-ledger-scheduler').spec.template.spec.terminationGracePeriodSeconds, 1800);
});
