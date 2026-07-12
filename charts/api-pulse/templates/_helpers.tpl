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

{{- define "api-pulse.web.image" -}}
{{ printf "%s/%s:%s" .Values.imageRegistry .Values.images.web.repository .Values.images.web.tag | trimPrefix "docker.io/" }}
{{- end -}}

{{- define "api-pulse.auth.image" -}}
{{ printf "%s/%s:%s" .Values.imageRegistry .Values.images.auth.repository .Values.images.auth.tag | trimPrefix "docker.io/" }}
{{- end -}}

{{- define "api-pulse.analytics.image" -}}
{{ printf "%s/%s:%s" .Values.imageRegistry .Values.images.analytics.repository .Values.images.analytics.tag | trimPrefix "docker.io/" }}
{{- end -}}
