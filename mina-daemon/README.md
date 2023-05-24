# `mina-daemon` helm chart

A Helm chart to deploy Mina protocol daemon node.

> **Note** Currently MF does not have chart repository. To install this chart i.e. with helmfile you need to reffer to it following ways:
```console
# helmfile.yaml
<..>
releases:
  - name: mina-daemon
    chart: git::https://git:accesstoken@github.com/MinaProtocol/mina-helm-charts-private.git@mina-daemon?ref=main
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
$ helmfile template | kubectl -f -
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
`node.exposeGraphql` | expose graphql to public | `false`
`node.metrics.enabled` | expose prometheus metrics endpoint | `false`
`node.metrics.port` | port to scrape prometheus metrics | `10001`
`node.ports.graphql` |  | `3085`
`node.archive.enabled` | Whether mina-daemon should connect to archive. | `false`
`node.archive.address` | mina-archive url | `staging-berkeley-archive:3086`
`node.statsUrl` | URL where to report node stats | ` `
`node.errorsUrl` | URL where to report node errors | ` `
`node.walletKeys.enabled` | Setup a wallet on a host | `false`
`node.daemonMode.blockProducer` | enable Block Producer mode | `false`
`node.daemonMode.snarkWorker` | enable SNARK Worker mode | `false`
`node.daemonMode.coordinator` | enable SNARK Coordinator mode | `false`
`node.daemonMode.seed` | enable Seed mode | `false`
`node.secrets.walletPassword` | Password for wallet keypair | ` `
`node.secrets.walletKey` | Private wallet keypair key | ` `
`node.secrets.walletPub` | Public wallet keypair key | ` `
`serviceAccount.annotations` | Allow role to assume this service account | `{}`
`requests.memory` | RAM allocated to mina-daemon container | "16.0Gi"
`requests.cpu` | # of CPUs allocated to mina-daemon container | "8"
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
    helmfile destroy
    ```

