{{/*
True when the daemon's full GraphQL API listens on every address, which is
what --insecure-rest-server does. Only with exposeGraphql, and only while
node.graphqlListen is `all`; with `localhost` the API stays inside the pod and
the graphql-public-proxy sidecar is the only way in.
*/}}
{{- define "mina-daemon.graphqlOnAllAddresses" -}}
{{- $listen := .Values.node.graphqlListen | default "all" -}}
{{- if not (has $listen (list "all" "localhost")) -}}
{{- fail (printf "node.graphqlListen must be all or localhost (got %q)" $listen) -}}
{{- end -}}
{{- if and .Values.node.exposeGraphql (eq $listen "all") -}}
{{- true -}}
{{- end -}}
{{- end -}}
