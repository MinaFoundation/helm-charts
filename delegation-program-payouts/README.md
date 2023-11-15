# Delegation Program Payouts

delegation-program-payouts is an API used by Mina Foundation to manage Delegation Program Payouts.

## TL;DR

```console
git clone https://github.com/MinaFoundation/helm-charts
cd helm-charts/delegation-program-payouts
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

The command deploys delegation-program-payouts on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `RELEASE_NAME` deployment:

```console
helm delete RELEASE_NAME
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters

| Name                                     | Description                                                                 | Value                       |
| ---------------------------------------- | --------------------------------------------------------------------------- | --------------------------- |
| `image.repository`                       | delegation-program-payouts image name                                       | `673156464838.dkr.ecr.us-west-2.amazonaws.com/github-actions-runner` |
| `image.pullPolicy`                       | delegation-program-payouts image pull policy                                | `IfNotPresent`              |
| `image.pullSecrets`                      | Specify docker-registry secret names as an array                            | `[]`                        |
| `nameOverride`                           | String to partially override common.names.fullname                          | ""                          |
| `fullnameOverride`                       | String to fully override common.names.fullname                              | ""                          |
| `serviceAccount.create`                  | Enable the creation of a ServiceAccount for delegation-program-payouts pods | `true`                      |
| `serviceAccount.annotations`             | Annotations for the created ServiceAccount                                  | {}                          |
| `serviceAccount.name`                    | Name of the created ServiceAccount                                          | ""                          |
| `podAnnotations`                         | Annotations for delegation-program-payouts pods                             | {}                          |
| `podLabels`                              | Extra labels for delegation-program-payouts pods                            | {}                          |
| `podRegexPattern`                        | Regex pattern to match pods                                                 | ".*"                        |
| `schedule`                               | Schedule to run pod rotation, runs every 6 hours                            | "0 */6 * * *"               |
| `restartPolicy`                          | Restart Policy when the job fails, can be OnFailure, Never, Always          | "OnFailure"                 |
| `podSecurityContext`                     | Set delegation-program-payouts Pod's Security Context                       | {}                          |
| `securityContext`                        | Set delegation-program-payouts Security Context                             | {}                          |
| `resources.limits`                       | The resources limits for the delegation-program-payouts container           | {}                          |
| `resources.requests`                     | The resources requests for the delegation-program-payouts container         | {}                          |
| `nodeSelector`                           | Node labels for pod assignment                                              | {}                          |
| `tolerations`                            | Tolerations for pod assignment                                              | {}                          |
| `affinity`                               | Affinity for pod assignment                                                 | {}                          |
| `payouts.appName`                        | Application Name                                                            | `MINA Delegation Program Payouts API` |
| `payouts.appEnv`                         | Environment Name                                                            | `demo` |
| `payouts.appKey`                         | Application Key (Base64)                                                    | `base64:AcjvbbjQqjm5l/6ynqNYCatc7Xuwd34ZjfS64S/lNYw=` |
| `payouts.appDebug`                       | Enable Debug Mode                                                           | `false` |
| `payouts.appUrl`                         | Application URL                                                             | `http://localhost` |
| `payouts.minaGraphqlEndpoint`            | Mina GraphQL Endpoint                                                       | `https://graphql.minaexplorer.com/` |
| `payouts.burnWalletAddress`              | Mina Wallet Burn Address                                                    | `62qiburnzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzmp7r7UN6X` |
| `payouts.advancedPayoutDebug`            | Advanced Payout Debug                                                       | `false` |
| `payouts.defaultCommissionRate`          | Default Commission Rate                                                     | `0.05` |
| `payouts.logChannel`                     | Log Channel                                                                 | `single` |
| `payouts.logDeprecationsChannel`         | Log Depreciation Channel                                                    | ` ` |
| `payouts.logLevel`                       | Application Log Level                                                       | `info` |
| `payouts.payoutsDbConnection`            | Payouts Database Connection                                                 | `pgsql` |
| `payouts.payoutsDbHost`                  | Payouts Database Host                                                       | `127.0.0.1` |
| `payouts.payoutsDbPort`                  | Payouts Database Port                                                       | `5432` |
| `payouts.payoutsDbDatabase`              | Payouts Database Name                                                       | `delegation_program_payouts` |
| `payouts.payoutsDbUsername`              | Payouts Database Username                                                   | `postgres` |
| `payouts.payoutsDbPassword`              | Payouts Database Password                                                   | ` ` |
| `payouts.archiveDbConnection`            | Archive Database Connection                                                 | `archive-db` |
| `payouts.archiveDbHost`                  | Archive Database Host                                                       | `mainnet-archive-temp.minaprotocol.network` |
| `payouts.archiveDbPort`                  | Archive Database Port                                                       | `5432` |
| `payouts.archiveDbDatabase`              | Archive Database Name                                                       | `archive_balances_migrated` |
| `payouts.archiveDbUsername`              | Archive Database Username                                                   | `postgres` |
| `payouts.archiveDbPassword`              | Archive Database Password                                                   | ` ` |
