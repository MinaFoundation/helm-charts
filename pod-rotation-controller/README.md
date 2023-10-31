# Pod Rotation Controller

pod-rotation-controller is a tools that rotates the oldest pod based on a Regex Pattern and a schedule.

## TL;DR

```console
git clone https://github.com/MinaFoundation/helm-charts
cd helm-charts/pod-rotation-controller
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

The command deploys pod-rotation-controller on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `RELEASE_NAME` deployment:

```console
helm delete RELEASE_NAME
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters

| Name                                     | Description                                         | Value                       |
| ---------------------------------------- | --------------------------------------------------- | --------------------------- |
| `image.repository`                       | pod-rotation-controller image name                  | `673156464838.dkr.ecr.us-west-2.amazonaws.com/github-actions-runner` |
| `image.pullPolicy`                       | pod-rotation-controller image pull policy           | `IfNotPresent`              |
| `image.pullSecrets`                      | Specify docker-registry secret names as an array    | `[]`                        |
| `nameOverride`                           | String to partially override common.names.fullname   | ""                          |
| `fullnameOverride`                       | String to fully override common.names.fullname       | ""                          |
| `serviceAccount.create`                  | Enable the creation of a ServiceAccount for pod-rotation-controller pods | `true` |
| `serviceAccount.annotations`             | Annotations for the created ServiceAccount          | {}                          |
| `serviceAccount.name`                    | Name of the created ServiceAccount                   | ""                          |
| `podAnnotations`                         | Annotations for pod-rotation-controller pods         | {}                          |
| `podLabels`                              | Extra labels for pod-rotation-controller pods        | {}                          |
| `podRegexPattern`                        | Regex pattern to match pods                          | ".*"                        |
| `schedule`                               | Schedule to run pod rotation, runs every 6 hours     | "0 */6 * * *"               |
| `restartPolicy`                          | Restart Policy when the job fails, can be OnFailure, Never, Always | "OnFailure" |
| `podSecurityContext`                     | Set pod-rotation-controller Pod's Security Context   | {}                          |
| `securityContext`                        | Set pod-rotation-controller Security Context          | {}                          |
| `resources.limits`                      | The resources limits for the pod-rotation-controller container | {}                   |
| `resources.requests`                    | The resources requests for the pod-rotation-controller container | {}                 |
| `nodeSelector`                          | Node labels for pod assignment                       | {}                          |
| `tolerations`                            | Tolerations for pod assignment                       | {}                          |
| `affinity`                               | Affinity for pod assignment                          | {}                          |
