### Mina Archive node healthcheck TEMPLATES ###

{{/*
mina-archive node startup probe settings
*/}}
{{- define "healthcheck.archive.startupCheck" }}
startupProbe:
  tcpSocket:
    port: archive-port
  periodSeconds: {{ default .healthcheck.startup.periodSeconds 30 }}
  failureThreshold: {{ default .healthcheck.startup.failureThreshold 10 }}
{{- end }}

{{/*
mina-archive node liveness/readiness check common settings
*/}}
{{- define "healthcheck.common.settings" }}
initialDelaySeconds: {{ default .healthcheck.initialDelaySeconds 30 }}
periodSeconds: {{ default .healthcheck.periodSeconds 5 }}
failureThreshold: {{ default .healthcheck.failureThreshold 5 }}
{{- end }}

{{/*
mina-archive node liveness check settings
*/}}
{{- define "healthcheck.archive.livenessCheck" }}
livenessProbe:
  tcpSocket:
    port: archive-port
{{- include "healthcheck.common.settings" . | indent 2 }}
{{- end }}

{{/*
mina-archive node readiness check settings
*/}}
{{- define "healthcheck.archive.readinessCheck" }}
readinessProbe:
  tcpSocket:
    port: archive-port
{{- include "healthcheck.common.settings" . | indent 2 }}
{{- end }}

{{/*
ALL mina-archive node healthchecks
*/}}
{{- define "healthcheck.archive.allChecks" }}
{{- if .healthcheck.enabled }}
{{- include "healthcheck.archive.startupCheck" . }}
{{- include "healthcheck.archive.livenessCheck" . }}
{{- include "healthcheck.archive.readinessCheck" . }}
{{- end }}
{{- end }}
