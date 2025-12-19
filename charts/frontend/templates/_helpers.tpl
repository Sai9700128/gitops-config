{{- define "frontend.labels" -}}
app: {{ .Chart.Name }}
{{- end }}

{{- define "frontend.selectorLabels" -}}
app: {{ .Chart.Name }}
{{- end }}
