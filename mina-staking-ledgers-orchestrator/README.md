# Mina Staking Ledger Orchestrator

mina-staking-ledgers-orchestrator is a tools that generate Mina Staking Ledgers, Publish them on S3 and Mina Payout Data Provider API.

## TL;DR

```console
git clone https://github.com/MinaFoundation/helm-charts
cd helm-charts/mina-staking-ledgers-orchestrator
helm install RELEASE_NAME ./ --namespace NAMESPACE
```

## Prerequisites

- Kubernetes 1.12+
- Helm 3.1.0

## Installing the Chart

To install the chart with the release name `RELEASE_NAME`:

```console
helm install RELEASE_NAME ./ --namespace NAMESPACE
```

The command deploys mina-staking-ledgers-orchestrator on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `RELEASE_NAME` deployment:

```console
helm delete RELEASE_NAME
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters

| Name                                                              | Description                                                                        | Value                                                                |
| ----------------------------------------------------------------- | ---------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `image.repository`                                                | mina-staking-ledgers-orchestrator image name                                       | `673156464838.dkr.ecr.us-west-2.amazonaws.com/github-actions-runner` |
| `image.pullPolicy`                                                | mina-staking-ledgers-orchestrator image pull policy                                | `IfNotPresent`                                                       |
| `image.pullSecrets`                                               | Specify docker-registry secret names as an array                                   | `[]`                                                                 |
| `nameOverride`                                                    | String to partially override common.names.fullname                                 | ""                                                                   |
| `fullnameOverride`                                                | String to fully override common.names.fullname                                     | ""                                                                   |
| `serviceAccount.create`                                           | Enable the creation of a ServiceAccount for mina-staking-ledgers-orchestrator pods | `true`                                                               |
| `serviceAccount.annotations`                                      | Annotations for the created ServiceAccount                                         | {}                                                                   |
| `serviceAccount.name`                                             | Name of the created ServiceAccount                                                 | ""                                                                   |
| `podAnnotations`                                                  | Annotations for mina-staking-ledgers-orchestrator pods                             | {}                                                                   |
| `podLabels`                                                       | Extra labels for mina-staking-ledgers-orchestrator pods                            | {}                                                                   |
| `podRegexPattern`                                                 | Regex pattern to match pods                                                        | ".*"                                                                 |
| `schedule`                                                        | Schedule to run pod rotation, runs every 6 hours                                   | "0 */6 * * *"                                                        |
| `restartPolicy`                                                   | Restart Policy when the job fails, can be OnFailure, Never, Always                 | "OnFailure"                                                          |
| `podSecurityContext`                                              | Set mina-staking-ledgers-orchestrator Pod's Security Context                       | {}                                                                   |
| `securityContext`                                                 | Set mina-staking-ledgers-orchestrator Security Context                             | {}                                                                   |
| `resources.limits`                                                | The resources limits for the mina-staking-ledgers-orchestrator container           | {}                                                                   |
| `resources.requests`                                              | The resources requests for the mina-staking-ledgers-orchestrator container         | {}                                                                   |
| `nodeSelector`                                                    | Node labels for pod assignment                                                     | {}                                                                   |
| `tolerations`                                                     | Tolerations for pod assignment                                                     | {}                                                                   |
| `affinity`                                                        | Affinity for pod assignment                                                        | {}                                                                   |
| `schedule`                                                        | Frequency to run the job                                                           | `0 0 * * *`                                                          |
| `restartPolicy`                                                   | Restart Policy                                                                     | `Never`                                                              |
| `minaStakingLedgersOrchestrator.network`                          | Network to run the Orchestrator against                                            | ` `                                                                  |
| `minaStakingLedgersOrchestrator.s3.bucket`                        | Bucket to upload the Mina Staking Ledgers                                          | ` `                                                                  |
| `minaStakingLedgersOrchestrator.s3.subpath`                       | Bucket subpath to upload the Mina Staking Ledgers                                  | ` `                                                                  |
| `minaStakingLedgersOrchestrator.minaNodeLabel`                    | Label of the Mina Daemon to execute Staking Ledger Generation                      | ` `                                                                  |
| `minaStakingLedgersOrchestrator.slackWebhookUrl`                  | Slack Webhook URL                                                                  | ` `                                                                  |
| `minaStakingLedgersOrchestrator.minaPayoutsDataProvider.url`      | Mina Payouts Data Provider URL                                                     | ` `                                                                  |
| `minaStakingLedgersOrchestrator.minaPayoutsDataProvider.username` | Mina Payouts Data Provider Username                                                | ` `                                                                  |
| `minaStakingLedgersOrchestrator.minaPayoutsDataProvider.password` | Mina Payouts Data Provider Password                                                | ` `                                                                  |
