{{/*
Expand the name of the chart.
*/}}
{{- define "decentralized-treasury.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "decentralized-treasury.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "decentralized-treasury.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "decentralized-treasury.labels" -}}
helm.sh/chart: {{ include "decentralized-treasury.chart" . }}
{{ include "decentralized-treasury.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "decentralized-treasury.selectorLabels" -}}
app.kubernetes.io/name: {{ include "decentralized-treasury.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{/* Each workload has a distinct identity. Global cloud annotations are not inherited. */}}
{{- define "decentralized-treasury.serviceAccountName" -}}
{{- $config := index .root.Values.serviceAccounts .component | default dict -}}
{{- if .root.Values.serviceAccount.create -}}
{{- $base := .root.Values.serviceAccount.name | default (include "decentralized-treasury.fullname" .root) -}}
{{- $config.name | default (printf "%s-%s" ($base | trunc 38 | trimSuffix "-") .component) -}}
{{- else -}}
{{- required (printf "serviceAccounts.%s.name is required when serviceAccount.create=false" .component) $config.name -}}
{{- end -}}
{{- end -}}

{{- define "decentralized-treasury.automount" -}}
{{- $config := index .root.Values.serviceAccounts .component | default dict -}}
{{- $value := .root.Values.serviceAccount.automount -}}
{{- if hasKey $config "automount" -}}{{- $value = $config.automount -}}{{- end -}}
{{- if or (ne .component "proving-scheduler") (not .root.Values.proving.worker.enabled) (not .root.Values.proving.worker.autoscale.enabled) -}}
false
{{- else -}}
{{- $value -}}
{{- end -}}
{{- end -}}

{{- define "decentralized-treasury.network" -}}
{{- $network := .Values.network -}}
{{- if not (has $network (list "mainnet" "devnet")) -}}
{{- fail "network must be mainnet or devnet" -}}
{{- end -}}
{{- range $config := list .Values.api .Values.apiMigrate .Values.indexer .Values.indexerApi .Values.processor .Values.processorApi .Values.web .Values.backoffice .Values.votingLedgerScheduler .Values.tallyScheduler .Values.proving.worker .Values.proving.scheduler -}}
{{- range $env := $config.extraEnvVars -}}
{{- if or (eq $env.name "MINA_NETWORK_ID") (and (eq $env.name "NETWORK") (ne ($env.value | default "" | toString) $network)) -}}
{{- fail "extraEnvVars must not override chart NETWORK or use removed MINA_NETWORK_ID" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $network -}}
{{- end -}}
