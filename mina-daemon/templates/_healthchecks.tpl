### Mina daemon node healthcheck TEMPLATES ###

{{/*
mina-daemon node startup probe settings
*/}}
{{- define "healthcheck.node.startupCheck" -}}
startupProbe:
  tcpSocket:
    port: external-port
  periodSeconds: {{ default .healthcheck.startup.periodSeconds 30 }}
  failureThreshold: {{ default .healthcheck.startup.failureThreshold 30 }}
{{- end -}}

{{/*
mina-daemon node liveness/readiness check common settings
*/}}
{{- define "healthcheck.common.settings" }}
initialDelaySeconds: {{ default .healthcheck.initialDelaySeconds 5 }}
periodSeconds: {{ default .healthcheck.periodSeconds 5 }}
failureThreshold: {{ default .healthcheck.failureThreshold 30 }}
{{- end }}

{{/*
mina-daemon node liveness settings
*/}}
{{- define "healthcheck.node.livenessCheck" }}
livenessProbe:
  exec:
    command: [
      "/bin/bash",
      "-c",
      "mina",
      "client",
      "status"
    ]
{{- include "healthcheck.common.settings" . | indent 2 }}
{{- end -}}

{{/*
mina-daemon node readiness settings
*/}}
{{- define "healthcheck.node.readinessCheck" }}
readinessProbe:
  exec:
    command: [
      "/bin/bash",
      "-c",
      "source /healthcheck/utilities.sh && isDaemonSynced && peerCountGreaterThan 0"
    ]
{{- include "healthcheck.common.settings" . | indent 2 }}
{{- end }}

{{/*
ALL mina-daemon node healthchecks
*/}}
{{- define "healthcheck.node.allChecks" }}
{{- if .healthcheck.enabled }}
{{- include "healthcheck.node.startupCheck" . }}
{{- include "healthcheck.node.livenessCheck" . }}
{{- include "healthcheck.node.readinessCheck" . }}
{{- end }}
{{- end }}
