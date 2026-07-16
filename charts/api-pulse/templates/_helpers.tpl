{{- define "api-pulse.name" -}}
api-pulse
{{- end -}}

{{- define "api-pulse.fullname" -}}
{{- .Release.Namespace -}}
{{- end -}}

{{- define "api-pulse.registry" -}}
{{- if .Values.ecr.accountId -}}
{{ printf "%s.dkr.ecr.%s.amazonaws.com" .Values.ecr.accountId .Values.ecr.region }}
{{- else -}}
{{ .Values.imageRegistry }}
{{- end -}}
{{- end -}}

{{- define "api-pulse.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets.enabled }}
imagePullSecrets:
  - name: {{ .Values.imagePullSecrets.name }}
{{- end }}
{{- end -}}

{{- define "api-pulse.image" -}}
{{- $registry := include "api-pulse.registry" .root -}}
{{- $repo := .repository -}}
{{- $tag := .tag -}}
{{ printf "%s/%s:%s" $registry $repo $tag }}
{{- end -}}

{{- define "api-pulse.versionedName" -}}
{{- printf "api-pulse-%s-%s" .service .tag -}}
{{- end -}}
