{{- define "task-service.labels" -}}
app: {{ .Chart.Name }}
{{- end }}

{{- define "task-service.selectorLabels" -}}
app: {{ .Chart.Name }}
{{- end }}
