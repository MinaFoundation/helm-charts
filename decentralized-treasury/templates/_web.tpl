{{/*
Browser-facing configuration for the Next.js app.

The four service URLs are same-origin paths behind the ingress, mirroring the
Caddyfile's /api, /indexer and /processor prefixes. Anything set explicitly in
web.publicEnv wins, so a deployment that fronts the APIs on their own hostnames
can override individual entries without restating the rest.
*/}}
{{- define "decentralized-treasury.webPublicEnv" -}}
{{- $base := .Values.web.publicBaseUrl | trimSuffix "/" -}}
{{- $derived := dict -}}
{{- if $base -}}
{{- $scheme := $base | splitList "://" | first -}}
{{- if and .Values.ingress.enabled (eq .Values.ingress.mode "host") -}}
{{/* Separate hostname per service, so same-origin paths do not apply. */}}
{{- with .Values.ingress.hosts.api -}}
{{- $_ := set $derived "NEXT_PUBLIC_TREASURY_API_URL" (printf "%s://%s" $scheme .) -}}
{{- end -}}
{{- with .Values.ingress.hosts.indexer -}}
{{- $_ := set $derived "NEXT_PUBLIC_INDEXER_API_URL" (printf "%s://%s" $scheme .) -}}
{{- end -}}
{{- with .Values.ingress.hosts.processor -}}
{{- $_ := set $derived "NEXT_PUBLIC_PROCESSOR_API_URL" (printf "%s://%s" $scheme .) -}}
{{- end -}}
{{- else -}}
{{- $_ := set $derived "NEXT_PUBLIC_TREASURY_API_URL" (printf "%s/api" $base) -}}
{{- $_ := set $derived "NEXT_PUBLIC_INDEXER_API_URL" (printf "%s/indexer" $base) -}}
{{- $_ := set $derived "NEXT_PUBLIC_PROCESSOR_API_URL" (printf "%s/processor" $base) -}}
{{- end -}}
{{- $_ := set $derived "NEXT_PUBLIC_MINA_NODE_URL" (printf "%s/mina/graphql" $base) -}}
{{- end -}}
{{- $_ := set $derived "NEXT_PUBLIC_TREASURY_OWNER_CONTRACT_ADDRESS" .Values.config.treasuryOwnerContractAddress -}}
{{- $_ := set $derived "NEXT_PUBLIC_LIFECYCLE_PERIOD_DURATION" (.Values.config.lifecyclePeriodDuration | toString) -}}
{{- $_ := set $derived "NEXT_PUBLIC_PROOFS_ENABLED" (.Values.config.proofsEnabled | toString) -}}
{{- $merged := merge (deepCopy .Values.web.publicEnv) $derived -}}
{{- range $key := keys $merged | sortAlpha }}
{{- $value := index $merged $key }}
{{- if not (empty ($value | toString)) }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end -}}
