{{- define "odin.name" -}}
odin
{{- end -}}

{{- define "odin.api.image" -}}
{{ printf "%s/%s:%s" .Values.imageRegistry .Values.images.api.repository .Values.images.api.tag | trimPrefix "docker.io/" }}
{{- end -}}

{{- define "odin.ui.image" -}}
{{ printf "%s/%s:%s" .Values.imageRegistry .Values.images.ui.repository .Values.images.ui.tag | trimPrefix "docker.io/" }}
{{- end -}}

{{- define "odin.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets.enabled }}
imagePullSecrets:
  - name: {{ .Values.imagePullSecrets.name }}
{{- end }}
{{- end -}}
