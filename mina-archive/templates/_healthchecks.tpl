### Mina Archive node healthcheck TEMPLATES ###

{{/*
mina-archive node startup probe settings
*/}}
{{- define "healthcheck.archive.startupCheck" }}
startupProbe:
  tcpSocket:
    port: archive-port
  periodSeconds: {{ default 30 .healthcheck.startup.periodSeconds }}
  failureThreshold: {{ default 10 .healthcheck.startup.failureThreshold }}
{{- end }}

{{/*
mina-archive node liveness/readiness check common settings
*/}}
{{- define "healthcheck.common.settings" }}
initialDelaySeconds: {{ default 10 .healthcheck.initialDelaySeconds }}
periodSeconds: {{ default 5 .healthcheck.periodSeconds }}
failureThreshold: {{ default 5 .healthcheck.failureThreshold }}
timeoutSeconds: {{ default 10 .healthcheck.timeoutSeconds }}
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
