# mina-staking-ledgers-provider

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

Exports Mina staking ledgers from an in-cluster daemon and publishes them to S3, named by ledger hash, for the decentralized treasury's voting ledger scheduler

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| MinaFoundation |  | <https://github.com/MinaFoundation> |

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
| affinity | object | `{}` | Affinity rules |
| exportNextEpoch | bool | `true` | Also export the next epoch's ledger. next(N) is byte-identical to staking(N+1), so publishing it early gives consumers up to a full epoch of head start on a build whose tracing step alone runs for hours. |
| extraEnvVars | list | `[]` | Additional environment variables for the fetch container |
| fullnameOverride | string | `""` | The full release name override. Worth setting to `mina-staking-ledgers-provider`: consumers address this by Service name, and the decentralized-treasury chart defaults to exactly that host. |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"alpine/k8s"` | Image for the fetch loop. Must provide kubectl, python3 and curl; it drives the Mina daemon through `kubectl exec`, since a staking ledger is available by no other interface. tar is NOT needed here - the archive is packed on the daemon pod. The script fails loudly at startup if any of the three is missing.  Public on purpose, so this chart carries no private-registry dependency. |
| image.tag | string | `"1.35.6"` | Image tag. Track the cluster's Kubernetes minor version: kubectl supports only +/-1 minor against the API server, and this uses exec and cp. |
| imagePullSecrets | list | `[]` | Image pull secrets |
| keepLastN | int | `4` | How many archives to keep, newest first. Generous on purpose: a treasury lifecycle can need a ledger several epochs old, and one the daemon has moved past cannot be re-exported at any price. |
| ledgersDirectory | string | `"/data"` | Where ledgers are written and served from |
| minaContainer | string | `"mina"` | Container name within the daemon pod |
| minaGraphqlPort | int | `3085` | GraphQL port on the daemon pod. Queried on the pod's own IP, not through a Service: the ledger hash must come from the very node the export runs on, and a Service balances across whatever matches its own selector - which is not the selector used to pick the synced pod here. That pre-check is what lets a cycle skip an export it does not need, and it also verifies the export afterwards. |
| minaNamespace | string | `""` | Namespace holding the Mina daemon. Empty means the release namespace. |
| minaNodeLabel | string | `""` | Label selector identifying candidate Mina daemon pods, e.g. `queryableNode=true`. Every match is probed and the first reporting `sync_status: Synced` is used - exporting from an unsynced node yields a ledger for a chain the network is not following. |
| minaNodeUrl | string | `""` | Cheap probe endpoint, typically a Service such as http://graphql-proxy:3085/graphql. Used only to decide whether there is any work to do: when the ledgers the chain advertises are already published the cycle ends there, having touched no pod at all - the common case, since an epoch lasts days and polling is hourly. Leaving it empty still works, but then every cycle execs into pods just to discover there is nothing to do.  Deliberately not trusted for the export itself; see minaGraphqlPort. |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| persistence.accessMode | string | `"ReadWriteOnce"` | Access mode. ReadWriteOnce is what EBS supports, which is why this chart serves over HTTP rather than sharing the volume with its consumer. |
| persistence.existingClaim | string | `""` | Use an existing claim instead of creating one |
| persistence.size | string | `"20Gi"` | Volume size. A devnet ledger is ~140MB raw and compresses to roughly a fifth of that, so this holds a comfortable number of epochs. |
| persistence.storageClass | string | `"ebs-gp3-encrypted"` | Storage class for the ledger volume |
| podAnnotations | object | `{}` | Annotations to add to the pod |
| podSecurityContext | object | `{"fsGroup":1000}` | Pod security context |
| pollIntervalSeconds | int | `3600` | How often to look for a new epoch, in seconds |
| rbac.create | bool | `true` | Create the Role and RoleBinding granting pod exec on the Mina daemon |
| replicaCount | int | `1` | Number of replicas. Must stay 1: the ledger volume is ReadWriteOnce and the fetch loop writes into it in place. The template refuses any other value. |
| resources | object | `{"limits":{"memory":"2Gi"},"requests":{"cpu":"100m","memory":"512Mi"}}` | Resources for the fetch container. The ledger is streamed through, but `mina ledger export` output is buffered locally before it is packed. |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsNonRoot":true,"runAsUser":1000}` | Security context for the fetch container. The image defaults to root, which it does not need: kubectl, curl and python3 all run fine unprivileged, and fsGroup above makes the ledger volume writable at uid 1000. |
| server.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| server.image.repository | string | `"nginxinc/nginx-unprivileged"` | Image for the serving container |
| server.image.tag | string | `"1.27-alpine"` | Image tag |
| server.port | int | `8080` | Port the ledger directory is served on. 8080 rather than 80 because the unprivileged nginx image cannot bind a privileged port. |
| server.resources | object | `{}` | Resources for the serving container |
| server.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsNonRoot":true,"runAsUser":101}` | Security context for the serving container |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Whether to create a service account |
| serviceAccount.name | string | `""` | Name of the service account to use |
| tolerations | list | `[]` | Tolerations |

