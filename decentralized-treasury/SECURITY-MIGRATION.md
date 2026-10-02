# Workload identity and public-server migration

These changes are prepared for Treasury chart 0.10.0 and ledger-provider chart 0.2.0. They are not published releases. Render checks do not establish deployed cloud or Kubernetes permissions.

## Identity boundaries

Each Treasury workload uses a distinct ServiceAccount. API, indexer API, processor API, web, backoffice, docs, proxy, Redis, workers, migration jobs, and artifact servers do not mount Kubernetes API tokens. Only the proving scheduler mounts a token when its worker autoscaler is enabled. Its Role permits `get` and `patch` on the named worker Deployment's scale subresource.

Global `serviceAccount.annotations` is rejected. Set cloud identity annotations under `serviceAccounts.<component>.annotations`:

| Component | Required cloud access |
| --- | --- |
| `api`, `processor` | Read only: list the relevant SQLite prefix and get its objects. |
| `tally-scheduler` | Read only: list/get required SQLite and proof prefixes. |
| `voting-ledger-scheduler` | Read source ledgers where configured; write only its SQLite, marker, and checkpoint prefixes. |
| `proving-scheduler` | Read required SQLite/proofs; write only its completed SQLite, proof, and marker prefixes. |
| All other components | No cloud credentials. Account annotations are rejected. |

The chart cannot inspect an IAM role's policy. Configure and verify those policies and exact ServiceAccount OIDC trust subjects outside Helm. Do not reuse the old writer role for the API or processor. `automountServiceAccountToken: false` disables the Kubernetes API token; it does not disable an IRSA or another workload-identity token injected by a webhook. The S3 containers and API disable EC2 instance-metadata credential fallback. Cluster controls must also deny direct node-metadata access and prevent broad node roles from reaching public pods.

With `serviceAccount.create=false`, provide a distinct `serviceAccounts.<component>.name` for each enabled workload. Inspect existing accounts for cloud annotations and external RoleBindings. The chart cannot remove unrelated cluster grants. Duplicate account names are rejected.

### Renamed accounts

An IAM trust policy that names the old account stops matching after the upgrade. Add the new subjects before rolling out. A role may be reused across components while least-privilege roles are prepared; the chart only requires distinct account names.

| Chart | Old account | New account |
| --- | --- | --- |
| Treasury | `<fullname>` | `<fullname>-<component>`, e.g. `<fullname>-api`, `<fullname>-proving-scheduler` |
| Ledger provider | `<fullname>` | unchanged for fetch (cloud role); new `<fullname>-serve` (no role) |

The trust subject is `system:serviceaccount:<namespace>:<account>`.

## Storage and routing

The artifact nginx container moves out of the proving scheduler into a separate `artifacts` Deployment. The existing `proving-scheduler` Service name now selects that server. Its SQLite and proof claims are read-only in the server. Enabling the server creates dedicated scheduler SQLite and proof PVCs, even if `proving.scheduler.persistence.enabled=false`. Size SQLite with `proving.scheduler.persistence.size` and proofs with `proving.scheduler.server.proofsStorageSize`. Both use the scheduler storage class.

The ledger provider uses separate `-fetch` and `-serve` Deployments. The public Service and existing ledger PVC names remain unchanged. Only fetch has the namespace-scoped pod list/get/exec Role. Serve has a distinct unannotated account, no API token, and read-only storage. Set `minaNamespace` to the narrow daemon namespace. Kubernetes RBAC does not restrict pod listing or exec by the configured label selector.

Both pairs use required same-node pod affinity for ReadWriteOnce volumes. The writer can bootstrap using its own matching label; a reader requires its writer. A restarted writer remains with its reader. Do not use ReadWriteOncePod storage for the two ledger pods. Verify provisioner support, node capacity, and topology before rollout. This is render-tested, not cluster-tested.

## Checkpoint shutdown

`votingLedgerScheduler.terminationGracePeriodSeconds` defaults to 1260 seconds.
A terminating trace can wait for an active ten-minute upload and then attempt another ten-minute upload.
The extra minute covers the current batch, local snapshot copies, and SQLite closure.
Increase this setting for slower measured local work. It does not extend a cloud provider's shorter spot interruption deadline.
Host loss or forced termination can still require recovery from the last valid checkpoint.

## Upgrade procedure

1. Back up current values, ledger data, and the scheduler's unuploaded SQLite/proof progress.
2. Set `network` explicitly; it no longer has a default. It stays the S3 key prefix, so keep the current value. Set `minaNetwork: mainnet` or `minaNetwork: devnet` when `network` is anything else, such as `singlenet` or `mainnet-trace`.
3. Remove `tallyScheduler.minaNetworkId`. CLI/proof workloads now receive `NETWORK` from `minaNetwork`. The S3 sync containers still receive `NETWORK` as the `network` prefix.
4. Remove conflicting browser `NEXT_PUBLIC_NETWORK_ID` overrides. Both browsers derive the same lowercase `minaNetwork`. Their verification keys must match it. `testnet` is no longer accepted by the app.
5. Move the old shared cloud annotation to distinct, least-privilege account settings. Update cloud trust subjects before rollout: the accounts are renamed (see Renamed accounts).
6. Review storage sizes and provisioner rules. Preserve the existing ledger PVC. Migrate scheduler progress or restore it from verified S3 artifacts.
7. Stop the old combined ledger-provider Deployment before the split deploys. This prevents overlapping fetch writers during the resource-name change.
8. Quiesce the old proving scheduler and save unuploaded progress. The new split uses dedicated shared claims instead of its former emptyDir caches.
9. Render and review the exact values. Verify account names, RoleBindings, tokens, cloud policies, Service selectors, and claim mounts.
10. Publish the reviewed charts and approve a separate rollout. Do not point a production pin at an unpublished version.

During rollout, verify that only fetch can exec into the selected daemon namespace and only the proving scheduler can scale its worker. Verify read/write cloud permissions through the actual workload identities. Public artifact and ledger HTTP requests must work without Kubernetes or cloud credentials.

## Verification

Run the local render regressions with Helm, Node, and Ruby's standard YAML library:

```sh
HELM_BIN=helm node --test --test-concurrency=1 tests/privilege-separation.test.mjs
```

The tests render both charts. They verify identity separation, token controls, role subjects, read-only PVCs, same-node affinity, routing, network consistency, and rejected unsafe legacy settings. They send no cluster requests and generate no cryptographic proofs.
