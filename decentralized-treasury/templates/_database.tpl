{{/*
Database connection helpers.

The chart takes its Postgres from exactly one of two places: the bundled
postgresql subchart, or an already-running instance described by
.Values.externalDatabase. Everything else in the chart consumes the resolved
values through "decentralized-treasury.databaseEnv".
*/}}

{{- define "decentralized-treasury.checkDatabaseConfig" -}}
{{- if and .Values.postgresql.enabled .Values.externalDatabase.enabled -}}
{{- fail "Enable either postgresql or externalDatabase, not both" -}}
{{- end -}}
{{- if not (or .Values.postgresql.enabled .Values.externalDatabase.enabled) -}}
{{- fail "Configuration should have either postgresql or externalDatabase enabled" -}}
{{- end -}}
{{- end -}}

{{- define "decentralized-treasury.databaseHost" -}}
{{- include "decentralized-treasury.checkDatabaseConfig" . -}}
{{- if .Values.externalDatabase.enabled -}}
{{- .Values.externalDatabase.host -}}
{{- else -}}
{{- include "postgresql.v1.primary.fullname" .Subcharts.postgresql -}}
{{- end -}}
{{- end -}}

{{- define "decentralized-treasury.databasePort" -}}
{{- include "decentralized-treasury.checkDatabaseConfig" . -}}
{{- if .Values.externalDatabase.enabled -}}
{{- .Values.externalDatabase.port | int -}}
{{- else -}}
{{- .Values.postgresql.primary.service.ports.postgresql | int -}}
{{- end -}}
{{- end -}}

{{- define "decentralized-treasury.databaseUser" -}}
{{- include "decentralized-treasury.checkDatabaseConfig" . -}}
{{- if .Values.externalDatabase.enabled -}}
{{- .Values.externalDatabase.username -}}
{{- else -}}
{{- .Values.postgresql.auth.username -}}
{{- end -}}
{{- end -}}

{{- define "decentralized-treasury.databasePassword" -}}
{{- include "decentralized-treasury.checkDatabaseConfig" . -}}
{{- if .Values.externalDatabase.enabled -}}
{{- .Values.externalDatabase.password -}}
{{- else -}}
{{- .Values.postgresql.auth.password -}}
{{- end -}}
{{- end -}}

{{- define "decentralized-treasury.databaseName" -}}
{{- include "decentralized-treasury.checkDatabaseConfig" . -}}
{{- if .Values.externalDatabase.enabled -}}
{{- .Values.externalDatabase.database -}}
{{- else -}}
{{- .Values.postgresql.auth.database -}}
{{- end -}}
{{- end -}}

{{/*
The DATABASE_URL the api workspace expects. The password is percent-encoded so
that most special characters survive, but a password containing a space is
better supplied through database.existingSecret than assembled here.
*/}}
{{- define "decentralized-treasury.databaseUrl" -}}
{{- $user := include "decentralized-treasury.databaseUser" . -}}
{{- $password := include "decentralized-treasury.databasePassword" . | urlquery -}}
{{- $host := include "decentralized-treasury.databaseHost" . -}}
{{- $port := include "decentralized-treasury.databasePort" . -}}
{{- $name := include "decentralized-treasury.databaseName" . -}}
{{- printf "postgres://%s:%s@%s:%s/%s" $user $password $host $port $name -}}
{{- end -}}

{{- define "decentralized-treasury.databaseSecretName" -}}
{{- if .Values.database.existingSecret -}}
{{- .Values.database.existingSecret -}}
{{- else -}}
{{- printf "%s-database" (include "decentralized-treasury.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Environment shared by every workload that talks to Postgres.
*/}}
{{- define "decentralized-treasury.databaseEnv" -}}
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "decentralized-treasury.databaseSecretName" . }}
      key: {{ .Values.database.existingSecretUrlKey }}
- name: DATABASE_SCHEMA
  value: {{ .Values.database.schema | quote }}
{{- end -}}
