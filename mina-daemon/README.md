# `mina-daemon` helm chart

A Helm chart to deploy Mina protocol daemon node.

> **Note** Currently MF does not have chart repository. To install this chart i.e. with helmfile you need to reffer to it following ways:
```console
# helmfile.yaml
<..>
releases:
  - name: mina-daemon
    chart: git::https://git:accesstoken@github.com/MinaFoundation/helm-charts.git@mina-daemon?ref=main
<..>
```

## Prerequisites

Before installing this Helm chart, you should have the following prerequisites:

 - Access to Kubernetes cluster
 - Helm installed on your local machine
 - Basic knowledge of Kubernetes and Helm
 - Keypair for p2p network
 - Keypair for block producing
 - Access to https://github.com/minaProtocol/mina-helm-charts-private
 - Optional: helmfile to install this chart

## Installation

To install this Helm chart, easiest is create a helmfile.yaml with needed values and run:

```bash
$ helmfile template
$ helmfile apply
```

Or use helmfile only to generate resources and apply them with kubectl like so:

```bash
$ helmfile template | kubectl apply -f -
```

You can get some inspiration from helmfiles in `examples` folder.

Verify that the chart is deployed successfully:

```bash
$ helmfile status #although kubectl probably would give better insights.
```

## Configuration

To get all available values in cloned `mina-helm-charts-private` do:

```bash
$ helm show values ./mina-daemon
```

The following table lists the configurable parameters of the `mina-daemon` chart and its common default values.

### Required Settings

Parameter | Description
--- | ---
`deployment.testnet` | "berkeley|devnet|mainnet"
`deployment.image` | image to use for mina daemon node.
`deployment.genesisLedgerURL` | a url to fetch external Genesis Ledger URL
`deployment.peerListURL` | a url for txt file containing seed peers.
`deployment.seedPeers` | a list of additional seed peers.
`node.libp2pKeys.enabled` | This is mandatory for mina-daemon to start.
`node.secrets.libp2pPassword` | Password for libp2p keypair | ` `
`node.secrets.discoveryLibp2p` | Private libp2p keypair key | ` `
`node.secrets.discoveryLibp2pPeerid` | Public libp2p keypair key | ` `

### Optional Settings

> **Note** This is only more notable list of values.

Parameter | Description | Default
--- | --- | ---
`deployment.uptime.enabled` | Whether to use [Block Producer uptime](https://github.com/MinaProtocol/mina/tree/develop/src/app/delegation_backend) service | `false`
`deployment.uptime.url` | BPU service url | ` `
`deployment.storeBlocks.enabled` | Whether to store precomputed blocks locally | `false`
`deployment.storeBlocks.storageClass` | Enable persistent volume for storing blocks | ` `
`deployment.storeBlocks.filename` | file name where to append blocks in `json` format | `precomputed_blocks.json`
`deployment.storeBlocks.directory` | Path where to store precomputed_blocks file | `/blocks`
`deployment.storeBlocks.sizePVC` | How much space to claim for volume | `5Gi`
`deployment.uptime.enabled` | Enable Uptime Service | default `false`
`deployment.uptime.url` | URL of the uptime service of the Mina delegation program | default ` `
`deployment.uptime.sendNodeCommitSha` | Whether to send the commit SHA used to build the node to the uptime service | default ` `
`node.exposeGraphql` | expose graphql to public | `false`
`node.metrics.enabled` | expose prometheus metrics endpoint | `false`
`node.metrics.port` | port to scrape prometheus metrics | `10001`
`node.ports.graphql` |  | `3085`
`node.archive.enabled` | Whether mina-daemon should connect to archive | `false`
`node.archive.address` | mina-archive url | `staging-berkeley-archive:3086`
`node.statsUrl` | URL where to report node stats | ` `
`node.errorsUrl` | URL where to report node errors | ` `
`node.walletKeys.enabled` | Setup a wallet on a host | `false`
`node.daemonMode.blockProducer` | enable Block Producer mode | `false`
`node.daemonMode.snarkWorker` | enable SNARK Worker mode | `false`
`node.daemonMode.coordinator` | enable SNARK Coordinator mode | `false`
`node.daemonMode.seed` | enable Seed mode | `false`
`node.snarkWorkerFee` | Fee for Snark Worker | ` `
`node.allPeersSeenMetric` | Whether to track the set of all peers ever seen for the all_peers metric | `false`
`node.archiveRocksDB` | Stores all the blocks heard in RocksDB | `false`
`node.coinbaseReceiver` | Address to send coinbase rewards to (if this node is producing blocks) | ` `
`node.background` | Run process on the background | `false`
`node.bindIP` | IP of network interface to use for peer connections | ` `
`node.contactInfo` | info used in node error report service (it could be either email address or discord username), it should be less than 200 characters | ` `
`node.currentProtocolVersion` | Current protocol version, only blocks with the same version accepted | ` `
`node.demoMode` | Run the daemon in demo-mode -- assume we're "synced" to the network instantly | ` `
`node.directPeer` | Peers to always send new messages to/from. These peers should also have you configured as a direct peer, the relationship is intended to be symmetric | ` `
`node.disableNodeStatus` | Disable reporting node status to other nodes | ` `
`node.enableFlooding` | Publish our own blocks/transactions to every peer we can find | ` `
`node.enablePeerExchange` | Help keep the mesh connected when closing connections | `true`
`node.externalIP` | External IP address for other nodes to connect to. You only need to set this if auto-discovery fails for some reason | ` `
`node.fileLogRotations` | Number of file log rotations before overwriting old logs | `50`
`node.gcStatInterval` | in mins for collecting GC stats for metrics | `15.000000`
`node.internalTracing` | Enables internal tracing into $config-directory/internal-tracing/internal-trace.json | `false`
`node.isolateNetwork` | Only allow connections to the peers passed on the command line or configured through GraphQL | `false`
`node.itnGraphQLPort` | GraphQL-server for incentivized testnet interaction | ` `
`node.itnKeys` | A comma-delimited list of Ed25519 public keys that are permitted to send signed requests to the incentivized testnet GraphQL server | ` `
`node.itnMaxLogs` | Maximum number of logs to store to be made available via GraphQL for incentivized testnet | ` `
`node.libp2pMetricsPort` | libp2p metrics server for scraping via Prometheus | ` `
`node.limitedGraphQLPort` | GraphQL-server for limited daemon interaction | ` `
`node.logBlockCreation` | Log the steps involved in including transactions and snark work in a block | `true`
`node.logPrecomputedBlocks` | Include precomputed blocks in the log | `false`
`node.logSnarkWorkGossip` | Log snark-pool diff received from peers | `false`
`node.logTxnPoolGossip` | Log transaction-pool diff received from peers | `false`
`node.minBlockReward` | Minimum reward a block produced by the node should have. Empty blocks are created if the rewards are lower than the specified threshold | ` `
`node.noSuperCatchup` | Don't use super-catchup | `false`
`node.openLimitedGraphQLPort` | Have the limited GraphQL server listen on all addresses, not just localhost (this is INSECURE, make sure your firewall is configured correctly!) | `false`
`node.peer` | initial "bootstrap" peers for discovery | ` `
`node.peerListFile` | path to a file containing "bootstrap" peers for discovery, one multiaddress per line | ` `
`node.peerListURL` | URL of seed peer list file. Will be polled periodically | ` `
`node.peerProtectionRate` | Proportion of peers to be marked as protected | `0.2`
`node.precomputedBlocksFile` | Path to write precomputed blocks to, for replay or archiving | ` `
`node.proofLevel` | Internal, for testing. Start or connect to a network with full proving (`full`), snark-testing with dummy proofs (`check`), or dummy proofs (`none`) | `full`
`node.proposedProtocolVersion` | Proposed protocol version to signal other nodes | ` `
`node.snarkWorkerParallelism` | Run the SNARK worker using this many threads. Equivalent to setting OMP_NUM_THREADS, but doesn't affect block production. | ` `
`node.stopTime` | in hours after which the daemon stops itself (only if there were no slots won within an hour after the stop time) | `168`
`node.tracing` | Trace into $config-directory/trace/$pid.trace | ` `
`node.uploadBlocksToGoogleCloud` | upload blocks to gcloud storage. Requires the environment variables GCLOUD_KEYFILE, NETWORK_NAME, and GCLOUD_BLOCK_UPLOAD_BUCKET | ` `
`node.uploadSubmitterKey` | Private key file for the uptime submitter. You cannot provide both `uptime-submitter-key` and `uptime-submitter-pubkey` | ` `
`node.uploadSubmitterPubkey` | Public key of the submitter to the Mina delegation program, for the associated private key that is being tracked by this daemon. You cannot provide both `uptime-submitter-key` and `uptime-submitter-pubkey` | ` `
`node.validationQueueSize` | size of the validation queue in the p2p network used to buffer messages (like blocks and transactions received on the gossip network) while validation is pending. If a transaction, for example, is invalid, we don't forward the message on the gossip net. If this queue is too small, we will drop messages without validating them. If it is too large, we are susceptible to DoS attacks on memory | `150`
`node.workReassignmentWait` | in ms before a snark-work is reassigned | `420000m`
`node.workSelection` | Choose work sequentially `seq` or randomly `rand` | `rand`
`node.secrets.walletPassword` | Password for wallet keypair | ` `
`node.secrets.walletKey` | Private wallet keypair key | ` `
`node.secrets.walletPub` | Public wallet keypair key | ` `
`node.daemonAddress` | Snark Coordinator Daemon Address. Require `node.walletKeys.enabled: false` | localhost:8301
`node.shutdownOnDisconnect` | Shutdown Snark Worker if disconnect. Require `node.walletKeys.enabled: false` | false
`serviceAccount.annotations` | Custom Annotations for the service account | `{}`
`podAnnotations` | Custom Annotations for the pod | `{}`
`ingress.enabled` | Enable Ingress | `false`
`ingress.labels` | Ingress Labels | `{}`
`ingress.annotations` | Ingress Annotations | `{}`
`ingress.className` | Ingress className | `{}`
`ingress.tls` | Ingress TLS | `false`
`ingress.hosts` | Ingress Hosts | `[]`
`service.type` | Service Type of the Mina Daemon | `ClusterIP`
`service.annotations` | Service Annotations of the Mina Daemon | `{}`
`service.labels` | Service Labels of the Mina Daemon | `{}`
`service.loadBalancerClass` | Service LoadBalancerClass of the Mina Daemon | ` `
`service.publishNotReadyAddresses` | Publish Not Ready Mina Daemon Service Adresses | `true`
`service.graphql.annotations` | Service Annotations for the Mina Daemon graphql endpoint | `{}`
`resources.ephemeralStorageRequest` | Ephemeral Storage to Request for mina-daemon container | ` `
`resources.memoryRequest` | RAM to claim for mina-daemon container | "16.0Gi"
`resources.cpuRequest` | # of CPUs to claim for mina-daemon container | "4"
`resources.ephemeralStorageLimit` | Ephemeral Storage Limit for mina-daemon container | ` `
`resources.memoryLimit` | RAM limit for mina-daemon container | "18.0Gi"
`resources.cpuLimit` | # of CPUs limit for mina-daemon container | "8"
`healthcheck.enabled` | Whether to use startup/liveness/readiness probes | true
`healthcheck.startup.periodSeconds` | startup probe specific | 30
`healthcheck.startup.failureThreshold` | startup probe specific | 30
`healthcheck.failureThreshold` | liveness/readiness probe specific | 10
`healthcheck.periodSeconds` | liveness/readiness probe specific | 5
`healthcheck.initialDelaySeconds` | liveness/readiness probe specific | 10
`healthcheck.timeoutSeconds` | liveness/readiness probe specific | 60

## Mina daemon nodes

Apart from other things, Mina daemon can run in 3 modes.

- Seed
- Block Producer
- SNARK Worker
- SNARK Coordinator
- Combination of the above

To run start Mina daemon with those modes set the following in values:

> **Note** Make sure you are providing appropriate libp2p and wallet keypairs and their passwords in secrets.

- `node.daemonMode.blockProducer = true`
- `node.daemonMode.snarkWorker = true`
- `node.daemonMode.coordinator = true`
- `node.daemonMode.seed = true`

> **Note** `snarkWorker` and `coordinator` mode are mutually exclusive. If `snarkWorker` is enabled, both `mina daemon` application as well as this helm chart ignore `coordinator` mode.

## Uninstallation

To uninstall the Helm chart using helmfile, follow these steps:

```bash
$ helmfile destroy
```
or
```bash
$ helmfile template . | kubectl delete -f -
```
