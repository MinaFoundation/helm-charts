{{/*
Expand the name of the chart.
*/}}
{{- define "mina-archive.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mina-archive.fullname" -}}
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
{{- define "mina-archive.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mina-archive.labels" -}}
helm.sh/chart: {{ include "mina-archive.chart" . }}
{{ include "mina-archive.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mina-archive.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mina-archive.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mina-archive.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mina-archive.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "check-db-config" }}
{{- if or .Values.externalDatabase.enabled .Values.postgresql.enabled }}
{{- else}}
{{- fail "Configuration should have either postgresql or externalDatabse enabled" }}
{{- end}}
{{- end}}

{{- define "databaseHost" -}}
{{ include "check-db-config" .}}
{{- if .Values.externalDatabase.enabled -}}
    {{- .Values.externalDatabase.host -}}
{{- else -}}
    {{ include "postgresql.v1.primary.fullname" .Subcharts.postgresql }}
{{- end -}}
{{- end -}}

{{- define "databasePort" -}}
{{ include "check-db-config" .}}
{{- if .Values.externalDatabase.enabled -}}
    {{- .Values.externalDatabase.port | int -}}
{{- else -}}
    {{- .Values.postgresql.primary.service.ports.postgresql -}}
{{- end -}}
{{- end -}}

{{- define "databaseUser" -}}
{{ include "check-db-config" .}}
{{- if .Values.externalDatabase.enabled -}}
    {{- .Values.externalDatabase.username -}}
{{- else -}}
    {{- .Values.postgresql.auth.username -}}
{{- end -}}
{{- end -}}

{{- define "databasePassword" -}}
{{ include "check-db-config" .}}
{{- if .Values.externalDatabase.enabled -}}
  {{ .Values.externalDatabase.password -}}
{{- else -}}
  {{ .Values.postgresql.auth.password -}}
{{- end -}}
{{- end -}}

{{- define "postgresUri" -}}
  postgres://{{ include "databaseUser" . }}:{{ include "databasePassword" . }}@{{ include "databaseHost" . }}:{{ include "databasePort" . }}/{{.Values.databaseName}}
{{- end }}

{{- define "bootstrapLockingDatabaseName" -}}
  {{ .Values.databaseName }}_locked
{{- end }}

{{- define "pgEnvVars" -}}
{{ include "check-db-config" .}}
- name: PGDATABASE
  value: {{ .Values.databaseName }}
- name: PGHOST
  value: {{ include "databaseHost" . }}
- name: PGPORT
  value: {{ include "databasePort" . | quote }}
- name: PGUSER
  value: {{ include "databaseUser" . }}
- name: PGPASSWORD
  value: {{ include "databasePassword" . | quote }}
- name: PG_CONN
  value: {{ include "postgresUri" . }}
{{- end}}
