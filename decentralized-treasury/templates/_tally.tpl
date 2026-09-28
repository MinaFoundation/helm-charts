{{/*
Pieces shared by the tally scheduler.
*/}}

{{/*
Name of the Secret holding the tally sender's private key: the operator's own
when sender.existingSecret is set, otherwise the one this chart renders from
sender.privateKey (secret-tally-sender.yaml).

Validates that exactly one of the two is set, and that an inline key looks like
a Mina private key, so a wrong value fails the render instead of the first
tally hours later.
*/}}
{{- define "decentralized-treasury.tallySenderSecretName" -}}
{{- $sender := .Values.tallyScheduler.sender -}}
{{- if and $sender.existingSecret $sender.privateKey -}}
{{- fail "tallyScheduler.sender: set existingSecret or privateKey, not both" -}}
{{- end -}}
{{- if $sender.existingSecret -}}
{{- $sender.existingSecret -}}
{{- else if $sender.privateKey -}}
{{- if not (hasPrefix "EK" $sender.privateKey) -}}
{{- fail "tallyScheduler.sender.privateKey must be a base58 Mina private key (EK...)" -}}
{{- end -}}
{{- printf "%s-sender" (include "decentralized-treasury.componentName" (dict "root" . "component" "tally-scheduler")) -}}
{{- else -}}
{{- fail "tallyScheduler.sender needs existingSecret or privateKey: the tally transaction is signed and its fee paid by this key" -}}
{{- end -}}
{{- end -}}
