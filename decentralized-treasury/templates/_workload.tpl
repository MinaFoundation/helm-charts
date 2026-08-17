{{/*
Pieces shared by every workload built from the application image.
*/}}

{{/*
Per-component naming and labels. The chart renders one workload per compose
service, so each gets a name and an app.kubernetes.io/component label derived
from a shared helper. Call with:

  (dict "root" $ "component" "indexer-api")
*/}}
{{- define "decentralized-treasury.componentName" -}}
{{- printf "%s-%s" (include "decentralized-treasury.fullname" .root) .component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "decentralized-treasury.componentLabels" -}}
{{ include "decentralized-treasury.labels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "decentralized-treasury.componentSelectorLabels" -}}
{{ include "decentralized-treasury.selectorLabels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{/*
In-cluster URLs for the services that call each other. Compose resolves these
through its own network aliases; here they are Service DNS names.
*/}}
{{- define "decentralized-treasury.indexerApiUrl" -}}
{{- if .Values.config.indexerApiUrl -}}
{{- .Values.config.indexerApiUrl -}}
{{- else -}}
{{- printf "http://%s:%v" (include "decentralized-treasury.componentName" (dict "root" . "component" "indexer-api")) .Values.indexerApi.service.port -}}
{{- end -}}
{{- end -}}

{{- define "decentralized-treasury.apiUrl" -}}
{{- if .Values.config.apiUrl -}}
{{- .Values.config.apiUrl -}}
{{- else -}}
{{- printf "http://%s:%v" (include "decentralized-treasury.componentName" (dict "root" . "component" "api")) .Values.api.service.port -}}
{{- end -}}
{{- end -}}

{{- define "decentralized-treasury.processorApiUrl" -}}
{{- if .Values.config.processorApiUrl -}}
{{- .Values.config.processorApiUrl -}}
{{- else -}}
{{- printf "http://%s:%v" (include "decentralized-treasury.componentName" (dict "root" . "component" "processor-api")) .Values.processorApi.service.port -}}
{{- end -}}
{{- end -}}

{{- define "decentralized-treasury.redisHost" -}}
{{- if .Values.proving.redis.externalHost -}}
{{- .Values.proving.redis.externalHost -}}
{{- else -}}
{{- include "decentralized-treasury.componentName" (dict "root" . "component" "redis") -}}
{{- end -}}
{{- end -}}

{{/*
Each service ships as its own image (minafoundation/dt-*), all built from the
same monorepo, so a component's tag falls back to the chart-wide one. Call with:

  (dict "root" $ "image" .Values.api.image)
*/}}
{{- define "decentralized-treasury.componentImage" -}}
{{- $repository := required "a component image.repository is required" .image.repository -}}
{{- $tag := .image.tag | default .root.Values.image.tag | default .root.Chart.AppVersion -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}

{{- define "decentralized-treasury.componentPullPolicy" -}}
{{- .image.pullPolicy | default .root.Values.image.pullPolicy -}}
{{- end -}}

{{/*
Name of the api-migrate Job.

Job pod templates are immutable, so the only way migrations run again is for the
Job to have a different name. That is what lets migrations stay a plain
declarative resource instead of a Helm hook.

Which token to vary is set by apiMigrate.rerunPolicy:

  revision (default) - a new Job on every helm upgrade. Required with a mutable
                       tag like `latest`, where the tag alone never changes and
                       a tag-keyed name would silently stop re-running.
  tag                - a new Job only when the image tag changes. Only correct
                       with immutable tags.

`migration:run` is idempotent, so the extra Job per upgrade is a cheap no-op
when there is nothing new to apply.
*/}}
{{- define "decentralized-treasury.apiMigrateName" -}}
{{- $token := "" -}}
{{- if eq .Values.apiMigrate.rerunPolicy "tag" -}}
{{- $token = sha1sum (.Values.apiMigrate.image.tag | default .Values.image.tag | default .Chart.AppVersion) | trunc 8 -}}
{{- else -}}
{{- $token = printf "r%d" (.Release.Revision | int) -}}
{{- end -}}
{{- printf "%s-migrate-%s" (include "decentralized-treasury.fullname" . | trunc 48 | trimSuffix "-") $token -}}
{{- end -}}

{{/*
Volume + mount for the ConfigMap holding the wait-for-* scripts.
*/}}
{{- define "decentralized-treasury.scriptsVolume" -}}
- name: scripts
  configMap:
    name: {{ include "decentralized-treasury.fullname" . }}-scripts
    defaultMode: 0555
{{- end -}}

{{- define "decentralized-treasury.scriptsVolumeMount" -}}
- name: scripts
  mountPath: /scripts
  readOnly: true
{{- end -}}

{{/*
Init container that blocks until the schema is migrated.

Included by every workload that reads the database, so that all of them can be
applied alongside the api-migrate Job and still start in the right order.

Runs from the component's own image rather than a shared one: every dt-* image
carries the whole monorepo, so each already has `pg` and the shipped migration
files. Call with:

  (dict "root" $ "image" .Values.api.image)
*/}}
{{- define "decentralized-treasury.waitForMigrations" -}}
{{- if .root.Values.migrationWait.enabled -}}
- name: wait-for-migrations
  image: {{ include "decentralized-treasury.componentImage" . }}
  imagePullPolicy: {{ include "decentralized-treasury.componentPullPolicy" . }}
  command: ["node", "/scripts/wait-for-migrations.mjs"]
  env:
    {{- include "decentralized-treasury.databaseEnv" .root | nindent 4 }}
    - name: API_DIRECTORY
      value: {{ .root.Values.apiDirectory | quote }}
    - name: WAIT_TIMEOUT_SECONDS
      value: {{ .root.Values.migrationWait.timeoutSeconds | quote }}
    - name: WAIT_POLL_INTERVAL_SECONDS
      value: {{ .root.Values.migrationWait.pollIntervalSeconds | quote }}
  {{- with .root.Values.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .root.Values.migrationWait.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  volumeMounts:
    {{- include "decentralized-treasury.scriptsVolumeMount" .root | nindent 4 }}
{{- end -}}
{{- end -}}
