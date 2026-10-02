{{- define "mina-staking-ledgers-provider.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mina-staking-ledgers-provider.fullname" -}}
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

{{- define "mina-staking-ledgers-provider.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mina-staking-ledgers-provider.labels" -}}
helm.sh/chart: {{ include "mina-staking-ledgers-provider.chart" . }}
{{ include "mina-staking-ledgers-provider.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "mina-staking-ledgers-provider.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mina-staking-ledgers-provider.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "mina-staking-ledgers-provider.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- /* Fetch keeps the pre-split name so an existing IRSA trust subject still matches. */ -}}
{{- default (include "mina-staking-ledgers-provider.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- required "serviceAccount.name is required when create=false" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "mina-staking-ledgers-provider.serverServiceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (printf "%s-serve" (include "mina-staking-ledgers-provider.fullname" . | trunc 57 | trimSuffix "-")) .Values.server.serviceAccountName -}}
{{- else -}}
{{- required "server.serviceAccountName is required when serviceAccount.create=false" .Values.server.serviceAccountName -}}
{{- end -}}
{{- end -}}
