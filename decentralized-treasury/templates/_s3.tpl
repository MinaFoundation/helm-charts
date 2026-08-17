{{/*
S3-backed SQLite cache.

The lifecycle databases are shared between four workloads, which Docker Compose
does with one host directory. Kubernetes has no equivalent that SQLite is safe
on - its own documentation warns against network filesystems - so instead each
pod keeps a real local copy and a sidecar mirrors S3 into it. Write ownership is
cleanly partitioned upstream (voting-ledger-scheduler owns bodies and .done,
proving-scheduler owns .proven and proofs), so nothing here has to lock.

The sidecar deliberately does not use the application image: it needs the AWS
CLI, which that image does not ship, and running a separate image avoids adding
a dependency to the app for a purely operational concern.

Credentials come from IRSA - annotate the service account with
eks.amazonaws.com/role-arn and the CLI picks the role up automatically, so no
secrets are needed in the chart.
*/}}

{{- define "decentralized-treasury.s3SyncEnv" -}}
- name: SQLITE_DATA_DIRECTORY
  value: {{ .root.Values.sqlite.dataDirectory | quote }}
- name: SQLITE_S3_BUCKET
  value: {{ required "s3.sqliteBucket is required" .root.Values.s3.sqliteBucket | quote }}
- name: NETWORK
  value: {{ required "network is required" .root.Values.network | quote }}
- name: AWS_REGION
  value: {{ .root.Values.s3.region | quote }}
- name: SQLITE_KEEP_LAST_N
  value: {{ .keepLastN | quote }}
{{- end -}}

{{/*
Pull-only cache sync. Call with:
  (dict "root" $ "name" "s3-sync" "oneshot" false "keepLastN" 0)

Use oneshot=true as an init container so a pod never starts serving from an
empty cache, and oneshot=false as a sidecar to keep it fresh.
*/}}
{{- define "decentralized-treasury.s3SyncPull" -}}
- name: {{ .name }}
  image: "{{ .root.Values.s3.syncImage.repository }}:{{ .root.Values.s3.syncImage.tag }}"
  imagePullPolicy: {{ .root.Values.s3.syncImage.pullPolicy }}
  command: ["/bin/sh", "/scripts/s3-sync-pull.sh"]
  env:
    {{- include "decentralized-treasury.s3SyncEnv" . | nindent 4 }}
    - name: SYNC_ONESHOT
      value: {{ .oneshot | quote }}
    - name: SYNC_INTERVAL_SECONDS
      value: {{ .root.Values.sqlite.syncIntervalSeconds | quote }}
    # The aws-cli image has no non-root home directory of its own.
    - name: HOME
      value: /tmp
  {{- with .root.Values.s3.syncImage.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .root.Values.s3.syncImage.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  volumeMounts:
    {{- include "decentralized-treasury.scriptsVolumeMount" .root | nindent 4 }}
    {{- include "decentralized-treasury.sqliteVolumeMount" .root | nindent 4 }}
{{- end -}}

{{/*
Push container for the two producer workloads. Call with:
  (dict "root" $ "name" "s3-push" "source" "/data/sqlite"
        "target" "s3://bucket/network" "payloads" "*.sqlite"
        "markers" "*.sqlite.done" "mounts" (list "sqlite-data"))
*/}}
{{- define "decentralized-treasury.s3SyncPush" -}}
- name: {{ .name }}
  image: "{{ .root.Values.s3.syncImage.repository }}:{{ .root.Values.s3.syncImage.tag }}"
  imagePullPolicy: {{ .root.Values.s3.syncImage.pullPolicy }}
  command: ["/bin/sh", "/scripts/s3-sync-push.sh"]
  env:
    - name: SOURCE_DIRECTORY
      value: {{ .source | quote }}
    - name: S3_TARGET_PREFIX
      value: {{ .target | quote }}
    - name: PUSH_PAYLOAD_INCLUDES
      value: {{ .payloads | default "" | quote }}
    - name: PUSH_MARKER_INCLUDES
      value: {{ .markers | default "" | quote }}
    - name: SYNC_INTERVAL_SECONDS
      value: {{ .root.Values.sqlite.syncIntervalSeconds | quote }}
    - name: AWS_REGION
      value: {{ .root.Values.s3.region | quote }}
    - name: HOME
      value: /tmp
  {{- with .root.Values.s3.syncImage.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .root.Values.s3.syncImage.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  volumeMounts:
    {{- include "decentralized-treasury.scriptsVolumeMount" .root | nindent 4 }}
    - name: {{ .volumeName | default "sqlite-data" }}
      mountPath: {{ .source }}
{{- end -}}

{{/*
Staking ledger mirror for voting-ledger-scheduler. Call with:
  (dict "root" $ "name" "staking-ledgers-sync" "oneshot" false)
*/}}
{{- define "decentralized-treasury.s3SyncStakingLedgers" -}}
- name: {{ .name }}
  image: "{{ .root.Values.s3.syncImage.repository }}:{{ .root.Values.s3.syncImage.tag }}"
  imagePullPolicy: {{ .root.Values.s3.syncImage.pullPolicy }}
  command: ["/bin/sh", "/scripts/s3-sync-staking-ledgers.sh"]
  env:
    - name: STAKING_LEDGERS_DIRECTORY
      value: {{ .root.Values.votingLedgerScheduler.stakingLedgersDirectory | quote }}
    - name: STAKING_LEDGERS_S3_BUCKET
      value: {{ required "s3.stakingLedgersBucket is required" .root.Values.s3.stakingLedgersBucket | quote }}
    - name: STAKING_LEDGERS_KEEP_LAST_N
      value: {{ .root.Values.votingLedgerScheduler.stakingLedgersKeepLastN | quote }}
    {{/*
    The sync only fetches archives that begin a lifecycle, and drops them once
    the voting ledger they produce is published - so it needs the same
    epoch-to-lifecycle arithmetic the scheduler entrypoint does, plus the
    bucket the products land in.
    */}}
    - name: SQLITE_S3_BUCKET
      value: {{ required "s3.sqliteBucket is required" .root.Values.s3.sqliteBucket | quote }}
    - name: LIFECYCLE_PERIOD_DURATION
      value: {{ required "config.lifecyclePeriodDuration is required" .root.Values.config.lifecyclePeriodDuration | quote }}
    - name: TREASURY_DEPLOYED_AT_SLOT
      value: {{ .root.Values.config.treasuryDeployedAtSlot | quote }}
    - name: PERIODS_PER_LIFECYCLE
      value: {{ .root.Values.votingLedgerScheduler.periodsPerLifecycle | quote }}
    - name: NETWORK
      value: {{ required "network is required" .root.Values.network | quote }}
    - name: AWS_REGION
      value: {{ .root.Values.s3.region | quote }}
    - name: SYNC_ONESHOT
      value: {{ .oneshot | quote }}
    - name: SYNC_INTERVAL_SECONDS
      value: {{ .root.Values.votingLedgerScheduler.stakingLedgersSyncIntervalSeconds | quote }}
    - name: HOME
      value: /tmp
  {{- with .root.Values.s3.syncImage.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .root.Values.s3.syncImage.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  volumeMounts:
    {{- include "decentralized-treasury.scriptsVolumeMount" .root | nindent 4 }}
    - name: staking-ledgers
      mountPath: {{ .root.Values.votingLedgerScheduler.stakingLedgersDirectory }}
{{- end -}}

{{- define "decentralized-treasury.sqliteVolumeMount" -}}
- name: sqlite-data
  mountPath: {{ .Values.sqlite.dataDirectory }}
{{- end -}}

{{/*
Local cache volume. emptyDir is the default because the cache is disposable -
it re-hydrates from S3 on start - but a claim is available for pods where
re-downloading on every restart would be too slow.
*/}}
{{- define "decentralized-treasury.sqliteVolume" -}}
- name: sqlite-data
{{- if .Values.sqlite.existingClaim }}
  persistentVolumeClaim:
    claimName: {{ .Values.sqlite.existingClaim }}
{{- else }}
  emptyDir:
    {{- with .Values.sqlite.sizeLimit }}
    sizeLimit: {{ . }}
    {{- end }}
{{- end }}
{{- end -}}
