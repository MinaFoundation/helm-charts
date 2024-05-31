# gpt-survey-summarizer

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A helm chart for the gptSuverySummarizer

**Homepage:** <https://github.com/MinaFoundation/gptSuverySummarizer>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Marton Szekely | <marton.szekely@minaprotocol.com> |  |

## Source Code

* <https://github.com/MinaFoundation/gptSuverySummarizer>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | redis | 19.1.0 |

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
| bot.args | list | `["bot"]` | Arguments for the bot container |
| bot.extraEnvVars | list | `[]` | Extra Environment Variables |
| bot.replicaCount | int | `1` | The number of pods to be deployed for bot |
| bot.serviceAccountAnnotations | object | `{}` | Annotations for the bot serviceAccount |
| config.discord.clientId | string | `""` | Discord Application ID |
| config.discord.guildId | string | `""` | Discord Guild/Server ID |
| config.discord.token | string | `""` | Discord API Token |
| config.openAiApiKey | string | `""` | Openai API Key |
| config.summarizeFrequencySeconds | int | `3600` | Summarize Frequency Seconds |
| databaseDumpExporter.enabled | bool | `true` | Whether to enable exporting of the database dump |
| databaseDumpExporter.s3Bucket | string | `"673156464838-gpt-survey-summarizer-backups"` | Full name of the S3 bucket for backups |
| databaseDumpExporter.schedule | string | `"@daily"` | Schedule of the automated exporter in crontab notation |
| databaseDumpExporter.serviceAccountAnnotations | object | `{}` | Annotations to add to the cronjob serviceAccount |
| databaseDumpExporter.suspended | bool | `false` | Suspend the automatic execution |
| databaseDumpExporter.ttlSecondsAfterFinished | int | `3600` | Time To Live after job finished in seconds |
| deploymentAnnotations | object | `{}` | Annotations to add to deployments |
| fullnameOverride | string | `""` | The full release name override |
| image.pullPolicy | string | `"IfNotPresent"` | The pullPolicy used when pulling the image |
| image.repository | string | `"673156464838.dkr.ecr.us-west-2.amazonaws.com/gpt-survey-summarizer"` | The repository of the image |
| image.tag | string | `"0.2.0-4a6bee4"` | The tag of the iamge. Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | The secrets used to pull the image |
| nameOverride | string | `""` | The release name override |
| nodeSelector | object | `{}` | Node selector labels |
| platform.name | string | `"sandbox"` |  |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podSecurityContext | object | `{}` | SecurityContext used for the pods |
| redis.architecture | string | `"standalone"` | The redis architecture (accepted values are: standalone, replication) |
| redis.auth.password | string | `""` | Redis password |
| redis.commonConfiguration | string | `"# Enable AOF https://redis.io/topics/persistence#append-only-file\nappendonly yes\n#\n# Backups:\n# * After 14400 seconds (4 hours) if at least 1 change was performed\n# * After 3600 seconds (1 hour) if at least 100 changes were performed\n# * After 600 seconds (10 minutes) if at least 10.000 changes were performed\n# \nsave 14400 1 3600 100 600 10000\n# Workdir of redis\ndir /data\n# Database file name\ndbfilename dump.rdb"` | Configuration to add to redis.conf |
| resources | object | `{}` | Resource limitations for the pods |
| securityContext | object | `{}` | SecurityContext |
| server.args | list | `["summarizer"]` | Arguments for the server container |
| server.extraEnvVars | list | `[]` | Extra Environment Variables |
| server.replicaCount | int | `1` | The number of pods to be deployed for server |
| server.serviceAccountAnnotations | object | `{}` | Annotations for the summarizer serviceAccount |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| tolerations | list | `[]` | Tolerations |

