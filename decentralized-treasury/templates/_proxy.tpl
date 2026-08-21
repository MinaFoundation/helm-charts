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
{{- $services = append $services (dict "strip" true "key" "api" "host" (include "decentralized-treasury.componentName" (dict "root" . "component" "api")) "port" .Values.api.service.port) -}}
{{- end -}}
{{- if .Values.indexerApi.enabled -}}
{{- $services = append $services (dict "strip" true "key" "indexer" "host" (include "decentralized-treasury.componentName" (dict "root" . "component" "indexer-api")) "port" .Values.indexerApi.service.port) -}}
{{- end -}}
{{- if .Values.processorApi.enabled -}}
{{- $services = append $services (dict "strip" true "key" "processor" "host" (include "decentralized-treasury.componentName" (dict "root" . "component" "processor-api")) "port" .Values.processorApi.service.port) -}}
{{- end -}}
{{/*
The lifecycle sqlite cache and the proofs, served read-only by the sidecar on
proving-scheduler. S3 stays the durable store; this is a view of the same bytes
that does not require handing out S3 credentials.
*/}}
{{- if and .Values.proving.enabled .Values.proving.scheduler.enabled .Values.proving.scheduler.server.enabled -}}
{{- $artifacts := include "decentralized-treasury.componentName" (dict "root" . "component" "proving-scheduler") -}}
{{/*
Both land on the same sidecar, so the prefix must survive the hop - the sidecar
is what tells /sqlite/ and /proofs/ apart. Stripping here would collapse them
onto the same root.
*/}}
{{- $services = append $services (dict "strip" false "key" "sqlite" "host" $artifacts "port" .Values.proving.scheduler.server.port) -}}
{{- $services = append $services (dict "strip" false "key" "proofs" "host" $artifacts "port" .Values.proving.scheduler.server.port) -}}
{{- end -}}
{{- range .Values.proxy.extraServices -}}
{{- $services = append $services (dict "strip" (ne .strip false) "key" .key "host" .host "port" .port) -}}
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
