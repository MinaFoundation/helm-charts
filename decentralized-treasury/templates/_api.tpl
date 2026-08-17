{{/*
Environment shared by every service built from the apps/api workspace.

apps/api/src/config.ts loads one config object for all entrypoints and validates
it eagerly at startup, so DATABASE_URL, ARCHIVE_NODE_URL and
TREASURY_OWNER_CONTRACT_ADDRESS must be present or the process exits. Everything
else there has an in-application default, so it is only emitted when set.

Per-service settings (ports, poll intervals) are added by the individual
templates rather than here - the compose file shares them through one YAML
anchor, but most services ignore most of them.
*/}}
{{- define "decentralized-treasury.apiEnv" -}}
{{- include "decentralized-treasury.databaseEnv" . }}
- name: ARCHIVE_NODE_URL
  value: {{ required "config.archiveNodeUrl is required" .Values.config.archiveNodeUrl | quote }}
- name: TREASURY_OWNER_CONTRACT_ADDRESS
  value: {{ required "config.treasuryOwnerContractAddress is required" .Values.config.treasuryOwnerContractAddress | quote }}
{{- with .Values.config.corsAllowedOrigins }}
- name: CORS_ALLOWED_ORIGINS
  value: {{ join "," . | quote }}
{{- end }}
{{- with .Values.config.apiPageLimitDefault }}
- name: API_PAGE_LIMIT_DEFAULT
  value: {{ . | quote }}
{{- end }}
{{- with .Values.config.apiPageLimitMax }}
- name: API_PAGE_LIMIT_MAX
  value: {{ . | quote }}
{{- end }}
{{- with .Values.config.archiveRequestTimeoutMs }}
- name: ARCHIVE_REQUEST_TIMEOUT_MS
  value: {{ . | quote }}
{{- end }}
{{- with .Values.config.processorName }}
- name: PROCESSOR_NAME
  value: {{ . | quote }}
{{- end }}
{{- end -}}
