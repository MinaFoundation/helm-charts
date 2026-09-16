{{/*
Browser-facing configuration for the break-glass console.

Unlike web, the backoffice talks to exactly one endpoint: the Mina node. Its
operations build and submit transactions directly, so the treasury, indexer and
processor API URLs are deliberately not derived here - they would only ever
appear in the in-app settings dialog. This mirrors the compose stack, which
passes the backoffice no API URLs either.

Anything set explicitly in backoffice.publicEnv wins, so a deployment that
fronts the Mina node somewhere else can override individual entries without
restating the rest.
*/}}
{{- define "decentralized-treasury.backofficePublicEnv" -}}
{{- $base := .Values.backoffice.publicBaseUrl | trimSuffix "/" -}}
{{- $derived := dict -}}
{{- if $base -}}
{{- $_ := set $derived "NEXT_PUBLIC_MINA_NODE_URL" (printf "%s/mina/graphql" $base) -}}
{{- end -}}
{{- $_ := set $derived "NEXT_PUBLIC_TREASURY_OWNER_CONTRACT_ADDRESS" .Values.config.treasuryOwnerContractAddress -}}
{{- $_ := set $derived "NEXT_PUBLIC_MULTISIG_PARTICIPANTS_PUBLIC_KEYS" (include "decentralized-treasury.multisigParticipants" .) -}}
{{- $_ := set $derived "NEXT_PUBLIC_LIFECYCLE_PERIOD_DURATION" (.Values.config.lifecyclePeriodDuration | toString) -}}
{{- $_ := set $derived "NEXT_PUBLIC_PROOFS_ENABLED" (.Values.config.proofsEnabled | toString) -}}
{{- $merged := merge (deepCopy .Values.backoffice.publicEnv) $derived -}}
{{- range $key := keys $merged | sortAlpha }}
{{- $value := index $merged $key }}
{{- if not (empty ($value | toString)) }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
The ordered multisig participant public keys, as the comma-separated string the
app expects.

Order is load-bearing twice over: the on-chain commitment is an ordered Poseidon
hash of the five keys, and signature i is verified against participant i. A list
that is merely the right set in the wrong order produces an invalid-commitment
failure at proving time, not a readable error.
*/}}
{{- define "decentralized-treasury.multisigParticipants" -}}
{{- join "," .Values.config.multisigParticipantsPublicKeys -}}
{{- end -}}

{{/*
Name of the htpasswd Secret the nginx ingress reads for basic auth, which is
either one supplied by the operator or the one this chart renders.
*/}}
{{- define "decentralized-treasury.backofficeAuthSecretName" -}}
{{- if .Values.backoffice.auth.basic.existingSecret -}}
{{- .Values.backoffice.auth.basic.existingSecret -}}
{{- else -}}
{{- printf "%s-auth" (include "decentralized-treasury.componentName" (dict "root" . "component" "backoffice")) -}}
{{- end -}}
{{- end -}}

{{/*
Whether the console is reachable from outside the cluster at all. Being
unreachable is the only state in which having no authentication is not a
finding, so this is what the validation below keys on.
*/}}
{{- define "decentralized-treasury.backofficeExposed" -}}
{{- if or .Values.ingress.hosts.backoffice .Values.backoffice.pathPrefix -}}
{{- true -}}
{{- end -}}
{{- end -}}

{{/*
Refuse to publish the console without an authentication layer.

It can pause the treasury and submit emergency withdrawals, and it has no login
of its own - it authenticates the *signers* by their Ledger devices, not whoever
opens the page. Whatever fronts it is therefore the only thing standing between
the internet and the pause button, so the chart makes the choice explicit rather
than defaulting to none.
*/}}
{{- define "decentralized-treasury.validateBackofficeAuth" -}}
{{- if include "decentralized-treasury.backofficeExposed" . -}}
{{- $mode := .Values.backoffice.auth.mode -}}
{{- $viaProxy := and .Values.backoffice.pathPrefix (eq .Values.ingress.mode "proxy") -}}
{{- if not (has $mode (list "basic" "external" "none")) -}}
{{- fail (printf "the backoffice is exposed (ingress.hosts.backoffice or backoffice.pathPrefix) but backoffice.auth.mode is %q. It can pause the treasury and has no login of its own, so set one of: `basic` (chart renders an htpasswd Secret and the nginx annotations), `external` (you supply the annotations for oauth2-proxy, ALB OIDC or similar in backoffice.ingress.annotations), or `none` to publish it unauthenticated deliberately." $mode) -}}
{{- end -}}
{{- if eq $mode "basic" -}}
{{- if and (not .Values.backoffice.auth.basic.users) (not .Values.backoffice.auth.basic.existingSecret) -}}
{{- fail "backoffice.auth.mode is `basic` but neither backoffice.auth.basic.users nor backoffice.auth.basic.existingSecret is set" -}}
{{- end -}}
{{- if and .Values.backoffice.auth.basic.users .Values.backoffice.auth.basic.existingSecret -}}
{{- fail "backoffice.auth.basic.users and backoffice.auth.basic.existingSecret are mutually exclusive" -}}
{{- end -}}
{{- if eq .Values.ingress.className "alb" -}}
{{- fail "backoffice.auth.mode is `basic` but ingress.className is `alb`: the AWS Load Balancer Controller does not implement the nginx basic-auth annotations, so the console would be published unauthenticated. Use `external` with the alb.ingress.kubernetes.io/auth-* OIDC annotations instead." -}}
{{- end -}}
{{- if $viaProxy -}}
{{- fail "backoffice.auth.mode is `basic` with backoffice.pathPrefix in ingress mode `proxy`: the controller only ever sees `/`, so its annotations cannot gate the path - the in-cluster nginx owns that route. Expose the console on ingress.hosts.backoffice instead, which the controller does route." -}}
{{- end -}}
{{- end -}}
{{- if eq $mode "external" -}}
{{- if not .Values.backoffice.ingress.annotations -}}
{{- fail "backoffice.auth.mode is `external` but backoffice.ingress.annotations is empty: there is nothing to enforce the authentication. Add the annotations your controller needs (nginx auth-url/auth-signin for oauth2-proxy, or alb.ingress.kubernetes.io/auth-* for ALB OIDC), or set `none` deliberately." -}}
{{- end -}}
{{- if $viaProxy -}}
{{- fail "backoffice.auth.mode is `external` with backoffice.pathPrefix in ingress mode `proxy`: the controller only ever sees `/`, so its annotations never reach that path. Expose the console on ingress.hosts.backoffice instead." -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Annotations for the console's Ingress: whatever the operator supplied, plus the
nginx basic-auth trio when the chart is the one enforcing it. Operator entries
win, so a stricter annotation can always be layered on top.
*/}}
{{- define "decentralized-treasury.backofficeIngressAnnotations" -}}
{{- $derived := dict -}}
{{- if eq .Values.backoffice.auth.mode "basic" -}}
{{- $_ := set $derived "nginx.ingress.kubernetes.io/auth-type" "basic" -}}
{{- $_ := set $derived "nginx.ingress.kubernetes.io/auth-secret" (include "decentralized-treasury.backofficeAuthSecretName" .) -}}
{{- $_ := set $derived "nginx.ingress.kubernetes.io/auth-realm" .Values.backoffice.auth.basic.realm -}}
{{- end -}}
{{- merge (deepCopy .Values.backoffice.ingress.annotations) $derived | toYaml -}}
{{- end -}}
