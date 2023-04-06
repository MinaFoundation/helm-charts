### Mina daemon node healthcheck TEMPLATES ###

{{/*
mina-daemon node startup probe settings
*/}}
{{- define "healthcheck.node.startupCheck" }}
startupProbe:
  tcpSocket:
    port: external-port
  periodSeconds: {{ default 30 .healthcheck.startup.periodSeconds }}
  failureThreshold: {{ default 30 .healthcheck.startup.failureThreshold }}
{{- end }}

{{/*
mina-daemon node liveness/readiness check common settings
*/}}
{{- define "healthcheck.common.settings" }}
initialDelaySeconds: {{ default 10 .healthcheck.initialDelaySeconds }}
periodSeconds: {{ default 5 .healthcheck.periodSeconds }}
failureThreshold: {{ default 10 .healthcheck.failureThreshold }}
timeoutSeconds: {{ default 60 .healthcheck.timeoutSeconds }}
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
      "source /healthcheck/utilities.sh && isDaemonSynced"
    ]
{{- include "healthcheck.common.settings" . | indent 2 }}
{{- end }}

{{/*
mina-daemon node readiness settings
*/}}
{{- define "healthcheck.node.readinessCheck" }}
readinessProbe:
  exec:
    command: [
      "/bin/bash",
      "-c",
      "source /healthcheck/utilities.sh && isDaemonSynced"
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
