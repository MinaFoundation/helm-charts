# mina-daemon

![Version: 2.1.0](https://img.shields.io/badge/Version-2.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.1.0](https://img.shields.io/badge/AppVersion-2.1.0-informational?style=flat-square)

A Helm chart for Mina Protocol's daemons

**Homepage:** <https://minaprotocol.com/>

## Prerequisites

Before using this Helm chart, you should have the following prerequisites:

- Access to Kubernetes cluster (If needed contact your friendly neighbourhood DevOps engineer)
- Helm >= v3.14.3
- (**Optional**) helmfile >= v0.162.0 to install this chart

## Installation

> Note: **examples** can be found in the repository

To install this Helm chart, the easiest is to create a helmfile.yaml with needed values and run:

```
helmfile template
helmfile apply
```

Or use helmfile only to generate resources and apply them with kubectl like so:

```
helmfile template | kubectl -f -
```

Verify that the chart is deployed successfully:

> Note: `kubectl` is a better suited tool for this

```
helmfile status
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| deployment.genesisLedgerURL | string | `nil` | Genesis ledger URL |
| deployment.image | string | `"minaprotocol/mina-daemon:1.3.2beta2-release-2.0.0-05c2f73-bulseye-berkeley"` | Image to use for the deployment |
| deployment.peerListURL | string | `"https://storage.googleapis.com/seed-lists/berkeley_seeds.txt"` | Peer list URL |
| deployment.seedPeers | list | `[]` | Seed peers |
| deployment.storeBlocks.aws.accessKeyID | string | `nil` | AWS S3 access key ID |
| deployment.storeBlocks.aws.bucket | string | `nil` | AWS S3 bucket |
| deployment.storeBlocks.aws.defaultRegion | string | `nil` | AWS S3 region |
| deployment.storeBlocks.aws.enabled | bool | `false` | Enable AWS S3 storage |
| deployment.storeBlocks.aws.prefix | string | `nil` | AWS S3 keyfile |
| deployment.storeBlocks.aws.secretKeyID | string | `nil` | AWS S3 secret access key |
| deployment.storeBlocks.aws.uploadInterval | int | `900` | AWS upload interval |
| deployment.storeBlocks.directory | string | `"/blocks"` | Block storage directory |
| deployment.storeBlocks.enabled | bool | `false` | Enable block storage |
| deployment.storeBlocks.gcp.bucket | string | `"mina_network_block_data"` | GCP bucket |
| deployment.storeBlocks.gcp.enabled | bool | `false` | Enable GCP storage |
| deployment.storeBlocks.gcp.keyfile | string | `"{}"` | GCP keyfile |
| deployment.storeBlocks.local.enabled | bool | `false` | Enable local storage |
| deployment.storeBlocks.local.filename | string | `"precomputed_blocks.json"` | Local storage filename |
| deployment.storeBlocks.sizePVC | string | `"5Gi"` | Block storage size |
| deployment.storeBlocks.storageClass | string | `nil` | Storage class |
| deployment.testnet | string | `"berkeley"` | Testnet |
| deployment.uptime.enabled | bool | `false` | Enable uptime monitoring |
| deployment.uptime.sendNodeCommitSha | string | `nil` | Send Node Commit SHA |
| deployment.uptime.url | string | `nil` | Uptime monitoring URL |
| graphqlPublicProxy.image.pullPolicy | string | `"IfNotPresent"` | The pull policy |
| graphqlPublicProxy.image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/mina-graphql-public-proxy"` | The image repository |
| graphqlPublicProxy.image.tag | string | `"0.0.12"` | The image tag |
| graphqlPublicProxy.resources.limits.cpu | string | `"200m"` | The CPU limit |
| graphqlPublicProxy.resources.limits.memory | string | `"256Mi"` | The memory limit |
| graphqlPublicProxy.resources.requests.cpu | string | `"100m"` | The CPU request |
| graphqlPublicProxy.resources.requests.memory | string | `"128Mi"` | The memory request |
| ingress.annotations | object | `{}` | Annotations to add to the Ingress |
| ingress.className | string | `""` | Ingress Class Name |
| ingress.enabled | bool | `false` | Enable Ingress |
| ingress.hosts | list | `[]` | The Ingress Hosts |
| ingress.labels | object | `{}` | Labels to add to the Ingress |
| ingress.tls | bool | `false` | TLS configuration |
| livenessProbe | object | `{"exec":{"command":["/bin/bash","-c","source /scripts/healthcheck.sh && check_liveness"]},"failureThreshold":3,"initialDelaySeconds":30,"periodSeconds":60,"successThreshold":1,"timeoutSeconds":30}` | The liveness probe |
| node.allPeersSeenMetric | string | `nil` | All Peers Seen Metric |
| node.archive.address | string | `"staging-berkeley-archive:3086"` | Archive URL |
| node.archive.enabled | bool | `false` | Enable archive |
| node.archiveRocksDB | string | `nil` | Archive RocksDB |
| node.background | string | `nil` | Background |
| node.bindIP | string | `nil` | Bind IP |
| node.clientTrustList | string | `"10.0.0.0/8"` | Client trust list |
| node.coinbaseReceiver | string | `nil` | Coinbase receiver |
| node.contactInfo | string | `nil` | Contact info |
| node.currentProtocolVersion | string | `nil` | Current protocol version |
| node.daemonAddress | string | `"localhost:8301"` | Daemon Address |
| node.daemonMode.blockProducer | bool | `false` | Enable Block Producer Daemon Mode |
| node.daemonMode.coordinator | bool | `false` | Enable Snark Coordinator Daemon Mode |
| node.daemonMode.seed | bool | `false` | Enable Seed Daemon Mode |
| node.daemonMode.snarkWorker | bool | `false` | Enable Snark Worker Daemon Mode |
| node.demoMode | string | `nil` | Demo mode |
| node.directPeer | string | `nil` | Direct peer |
| node.disableNodeStatus | string | `nil` | Disable Node Status |
| node.discoveryExternalIp | object | `{"enabled":false,"targetDNS":"example.nlb.us-west-2.amazonaws.com"}` | Discovery External IP |
| node.discoveryExternalIp.enabled | bool | `false` | Enable Discovery External IP |
| node.discoveryExternalIp.targetDNS | string | `"example.nlb.us-west-2.amazonaws.com"` | Target DNS |
| node.enableFlooding | string | `nil` | Enable Flooding |
| node.enablePeerExchange | bool | `true` | Enable Peer Exchange |
| node.errorsUrl | string | `nil` | Nodes Errors URL |
| node.exposeGraphql | bool | `false` | Expose GraphQL |
| node.externalIP | string | `nil` | External IP |
| node.extraEnvVars | object | `{}` | Extra environment variables for the mina daemon process |
| node.fileLogLevel | string | `"Error"` | File log level |
| node.fileLogRotations | string | `nil` | File Log Rotations |
| node.fullname | string | `"berkeley-node"` | Full name |
| node.gcStatInterval | string | `nil` | Garbage Collection Stat Interval |
| node.generateGenesisProof | string | `nil` | Generate genesis proof |
| node.internalTracing | string | `nil` | Internal Tracing |
| node.isolateNetwork | string | `nil` | Isolate Network |
| node.itnGraphQLPort | string | `nil` | ITN GraphQL Port |
| node.itnKeys | string | `nil` | ITN Keys |
| node.itnMaxLogs | string | `nil` | ITN Max Logs |
| node.libp2pKeys.create | bool | `false` | Generate Libp2p keypair |
| node.libp2pKeys.enabled | bool | `true` | Enable libp2p keys |
| node.libp2pKeys.legacy | bool | `false` | Use Legacy Libp2p keypair |
| node.libp2pMetricsPort | string | `nil` | Libp2p Metrics Port |
| node.limitedGraphQLPort | string | `nil` | Limited GraphQL Port |
| node.logBlockCreation | string | `nil` | Log Block Creation |
| node.logLevel | string | `"Info"` | Log level |
| node.logPrecomputedBlocks | string | `nil` | Log Precomputed Blocks |
| node.logSnarkWorkGossip | string | `nil` | Log Snark Work Gossip |
| node.logTxnPoolGossip | string | `nil` | Log Txn Pool Gossip |
| node.maxConnections | int | `200` | Max connections |
| node.metrics.enabled | bool | `false` | Enable metric service |
| node.metrics.port | int | `10001` | Metric port number |
| node.minBlockReward | string | `nil` | Min Block Reward |
| node.minConnections | string | `nil` | Min Connections |
| node.name | string | `"berkeley-node"` | Node name |
| node.noSuperCatchup | string | `nil` | No Super Catchup |
| node.openLimitedGraphQLPort | string | `nil` | Open Limited GraphQL Port |
| node.peer | string | `nil` | Peers |
| node.peerListFile | string | `nil` | Peer List File |
| node.peerListURL | string | `nil` | Peer List URL |
| node.peerProtectionRate | string | `nil` | Peer Protection Rate |
| node.ports.client | int | `8301` | Mina daemon client port number |
| node.ports.graphql | int | `3085` | Mina daemon graphql port number |
| node.ports.p2p | int | `10801` | Mina daemon libp2p port number |
| node.ports.proxy | int | `3000` | Mina daemon graphql proxy port number |
| node.precomputedBlocksFile | string | `nil` | Precomputed Blocks File |
| node.proofLevel | string | `nil` | Proof Level |
| node.proposedProtocolVersion | string | `nil` | Proposed Protocol Version |
| node.replicas | int | `1` | Number of replicas |
| node.role | string | `nil` | Node role |
| node.secrets.discoveryLibp2p | string | `""` | Discovery Libp2p Key |
| node.secrets.discoveryLibp2pPeerid | string | `""` | Discovery Libp2p Peerid |
| node.secrets.libp2pPassword | string | `""` | Libp2p Password |
| node.secrets.walletKey | string | `""` | Wallet Key |
| node.secrets.walletPassword | string | `""` | Wallet Password |
| node.secrets.walletPub | string | `""` | Wallet Public Key |
| node.shutdownOnDisconnect | bool | `false` | Shutdown on Disconnect |
| node.snarkWorkerFee | string | `nil` | Snark worker fee |
| node.snarkWorkerParallelism | string | `nil` | Snark Worker Parallelism |
| node.statsUrl | string | `nil` | Nodes Stats URL |
| node.stopTime | string | `nil` | Stop Time |
| node.tracing | string | `nil` | Tracing |
| node.uploadSubmitterKey | string | `nil` | Upload Submitter Key |
| node.uploadSubmitterPubkey | string | `nil` | Upload Submitter Pubkey |
| node.validationQueueSize | string | `nil` | Validation Queue Size |
| node.walletKeys.enabled | bool | `false` | Enable wallet keys |
| node.workReassignmentWait | string | `nil` | Work Reassignment Wait |
| node.workSelection | string | `nil` | Work Selection |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | Labels to add to the pods |
| readinessProbe | object | `{"exec":{"command":["/bin/bash","-c","source /scripts/healthcheck.sh && check_readiness"]},"failureThreshold":2,"initialDelaySeconds":1200,"periodSeconds":60,"successThreshold":1,"timeoutSeconds":60}` | The readiness probe |
| resources.cpuLimit | string | `"8"` | The CPU Limit |
| resources.cpuRequest | string | `"4"` | The CPU Request |
| resources.ephemeralStorageLimit | string | `nil` | The Ephemeral Storage Limit |
| resources.ephemeralStorageRequest | string | `nil` | The Ephemeral Storage Request |
| resources.memoryLimit | string | `"16.0Gi"` | The Memory Limit |
| resources.memoryRequest | string | `"16.0Gi"` | The Memory Request |
| s3BlocksUploader.image.pullPolicy | string | `"IfNotPresent"` | The pull policy |
| s3BlocksUploader.image.repository | string | `"amazon/aws-cli"` | The image repository |
| s3BlocksUploader.image.tag | string | `"latest"` | The image tag |
| s3BlocksUploader.resources.cpuLimit | string | `"2"` | The cpu limit |
| s3BlocksUploader.resources.cpuRequest | string | `"1"` | The cpu request |
| s3BlocksUploader.resources.ephemeralStorageLimit | string | `nil` | The ephemeral storage limit |
| s3BlocksUploader.resources.ephemeralStorageRequest | string | `nil` | The ephemeral storage request |
| s3BlocksUploader.resources.memoryLimit | string | `"256Mi"` | The memory limit |
| s3BlocksUploader.resources.memoryRequest | string | `"128Mi"` | The memory request |
| service.daemon.annotations | object | `{}` | The annotations to add to the service |
| service.daemon.labels | object | `{}` | The labels to add to the service |
| service.daemon.loadBalancerClass | string | `nil` | The load balancer class |
| service.daemon.publishNotReadyAddresses | bool | `true` | Publish not ready addresses |
| service.daemon.type | string | `"ClusterIP"` | The service type |
| service.graphql.annotations | object | `{}` | The annotations to add to the service |
| service.graphql.loadBalancerClass | string | `nil` | The load balancer class |
| service.graphql.publishNotReadyAddresses | bool | `false` | Publish not ready addresses |
| service.graphql.type | string | `"ClusterIP"` | The service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| updateStrategy.type | string | `"Recreate"` | The update strategy type |

