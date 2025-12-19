{{- define "mysql.labels" -}}
app: {{ .Chart.Name }}
{{- end }}

{{- define "mysql.selectorLabels" -}}
app: {{ .Chart.Name }}
{{- end }}
