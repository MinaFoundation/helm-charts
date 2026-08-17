{{/*
Pieces shared by the in-cluster reverse proxy.
*/}}

{{/*
The HTTP APIs the proxy fronts, as a JSON array of

  {"key": "api", "host": "<service>", "port": 4000}

keyed by the path prefix the browser calls. JSON rather than a list of dicts
because a template can only return a string, and the config template needs the
ports back as numbers.
*/}}
{{- define "decentralized-treasury.proxyServices" -}}
{{- $services := list -}}
{{- if .Values.api.enabled -}}
{{- $services = append $services (dict "key" "api" "host" (include "decentralized-treasury.componentName" (dict "root" . "component" "api")) "port" .Values.api.service.port) -}}
{{- end -}}
{{- if .Values.indexerApi.enabled -}}
{{- $services = append $services (dict "key" "indexer" "host" (include "decentralized-treasury.componentName" (dict "root" . "component" "indexer-api")) "port" .Values.indexerApi.service.port) -}}
{{- end -}}
{{- if .Values.processorApi.enabled -}}
{{- $services = append $services (dict "key" "processor" "host" (include "decentralized-treasury.componentName" (dict "root" . "component" "processor-api")) "port" .Values.processorApi.service.port) -}}
{{- end -}}
{{- $services | toJson -}}
{{- end -}}

{{/*
Headers every proxied route sets. Host is preserved so the app sees the public
hostname, and the forwarded headers are what let it know the original request
was HTTPS even though the load balancer forwards plain HTTP.
*/}}
{{- define "decentralized-treasury.proxyHeaders" -}}
proxy_http_version 1.1;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $forwarded_proto;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $connection_upgrade;
proxy_read_timeout {{ .Values.proxy.readTimeoutSeconds }}s;
{{- end -}}
