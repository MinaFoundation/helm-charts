### Mina Seed node healthcheck TEMPLATES ###

{{/*
seed-node startup probe settings
*/}}
{{- define "healthcheck.seed.startupProbe" -}}
{{- include "healthcheck.daemon.startupProbe" . }}
{{- end -}}

{{/*
seed-node liveness settings
*/}}
{{- define "healthcheck.seed.livenessCheck" -}}
{{- include "healthcheck.daemon.livenessCheck" . }}
{{- end -}}

{{/*
seed-node readiness settings
*/}}

{{/*
ALL seed-node healthchecks - TODO: readd startupProbes once GKE clusters have been updated to 1.16
*/}}
{{- define "healthcheck.seed.allChecks" }}
{{- if .healthcheck.enabled }}
{{- include "healthcheck.seed.livenessCheck" . }}
{{- end }}
{{- end }}
