{{- define "user-service.labels" -}}
app: {{ .Chart.Name }}
{{- end }}

{{- define "user-service.selectorLabels" -}}
app: {{ .Chart.Name }}
{{- end }}
