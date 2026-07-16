{{- define "odin.name" -}}
odin
{{- end -}}

{{- define "odin.registry" -}}
{{- if .Values.ecr.accountId -}}
{{ printf "%s.dkr.ecr.%s.amazonaws.com" .Values.ecr.accountId .Values.ecr.region }}
{{- else -}}
{{ .Values.imageRegistry }}
{{- end -}}
{{- end -}}

{{- define "odin.api.image" -}}
{{ printf "%s/%s:%s" (include "odin.registry" .) .Values.images.api.repository .Values.images.api.tag }}
{{- end -}}

{{- define "odin.ui.image" -}}
{{ printf "%s/%s:%s" (include "odin.registry" .) .Values.images.ui.repository .Values.images.ui.tag }}
{{- end -}}

{{- define "odin.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets.enabled }}
imagePullSecrets:
  - name: {{ .Values.imagePullSecrets.name }}
{{- end }}
{{- end -}}
