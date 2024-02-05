# Uptime Service Payloads Scrapper

A chart scrapping payload from Uptime Service

## TL;DR

```console
git clone https://github.com/MinaFoundation/helm-charts
cd helm-charts/uptime-service-payloads-scrapper
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

The command deploys `uptime-service-payloads-scrapper` on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `RELEASE_NAME` deployment:

```console
helm delete RELEASE_NAME
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

### Parameters

| Name                                         | Description                                                          | Value |
| -------------------------------------------- | -------------------------------------------------------------------- | ----- |
| `image.repository`                           | `uptime-service-payloads-scrapper` Docker Image URL                  | `673156464838.dkr.ecr.us-west-2.amazonaws.com/uptime-service-payloads-scrapper` |
| `image.tag`                                  | Docker Image Tag                                                     | `1.0.0-6e0b3ec` |
| `image.pullPolicy`                           | Docker Image Pull Policy                                             | `IfNotPresent` |
| `imagePullSecrets`                           | Secrets name used for Pulling the Docker Image                       | `""` |
| `nameOverride`                               | Name override                                                        | `""` |
| `fullnameOverride`                           | Fullname override                                                    | `""` |
| `serviceAccount.create`                      | Specifies whether a Service Account should be created                | `true` |
| `serviceAccount.annotations`                 | Annotations to add to the Service Account                            | `{}` |
| `podAnnotations`                             | Annotations to add to the pods                                       | `{}` |
| `podSecurityContext`                         | Pod Security Context                                                 | `{}` |
| `securityContext`                            | Security Context                                                     | `{}` |
| `service.type`                               | Service Type (`ClusterIP`, `LoadBalancer` or `NodePort`)             | `ClusterIP` |
| `service.port`                               | Service Port                                                         | `8080` |
| `ingress.enabled`                            | Enable Ingress                                                       | `false` |
| `ingress.enabled`                            | Enable className                                                     | `""` |
| `ingress.annotations`                        | Annotations to add to the Ingress                                    | `""` |
| `ingress.hosts`                              | Ingress Hosts                                                        | `[]` |
| `ingress.tls`                                | Ingress TLS                                                          | `[]` |
| `resources`                                  | Resources allocated to the pods                                      | `{}` |
| `autoscaling.enabled`                        | Enable Autoscaler                                                    | `false` |
| `autoscaling.minReplicas`                    | Autoscaler Min Replicas                                              | `1` |
| `autoscaling.maxReplicas`                    | Autoscaler Max Replicas                                              | `5` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU Utilization Percentage                                    | `80` |
| `nodeSelector`                               | Override Node Selector                                               | `{}` |
| `tolerations`                                | Set Tolerations                                                      | `[]` |
| `affinity`                                   | Set Affinity                                                         | `{}` |
| `persistence.enabled`                        | Enable Persitence                                                    | `false` |
| `persistence.storageClass`                   | Set Persitence Storage Class                                         | `ebs-gp3-encrypted` |
| `persistence.accessMode`                     | Set Access Mode (`ReadWriteOnce`, `ReadOnlyMany` or `ReadWriteMany`) | `ReadWriteOnce` |
| `persistence.size`                           | Size allocated to the PVC                                            | `10Gi` |
| `persistence.annotations`                    | Annotations added to the PVC                                         | `{}` |
