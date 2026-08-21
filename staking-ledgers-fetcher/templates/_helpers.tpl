{{- define "staking-ledgers-fetcher.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "staking-ledgers-fetcher.fullname" -}}
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

{{- define "staking-ledgers-fetcher.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "staking-ledgers-fetcher.labels" -}}
helm.sh/chart: {{ include "staking-ledgers-fetcher.chart" . }}
{{ include "staking-ledgers-fetcher.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "staking-ledgers-fetcher.selectorLabels" -}}
app.kubernetes.io/name: {{ include "staking-ledgers-fetcher.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "staking-ledgers-fetcher.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "staking-ledgers-fetcher.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
