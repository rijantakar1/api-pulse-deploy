{{- define "api-pulse.name" -}}
api-pulse
{{- end -}}

{{- define "api-pulse.fullname" -}}
{{- .Release.Namespace -}}
{{- end -}}

{{- define "api-pulse.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets.enabled }}
imagePullSecrets:
  - name: {{ .Values.imagePullSecrets.name }}
{{- end }}
{{- end -}}

{{- define "api-pulse.image" -}}
{{- $registry := .root.Values.imageRegistry -}}
{{- $repo := .repository -}}
{{- $tag := .tag -}}
{{ printf "%s/%s:%s" $registry $repo $tag | trimPrefix "docker.io/" }}
{{- end -}}

{{- define "api-pulse.versionedName" -}}
{{- printf "api-pulse-%s-%s" .service .tag -}}
{{- end -}}
