{{/*
Common labels. Call with: (dict "root" $ "name" $name)
*/}}
{{- define "shoplite.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .root.Chart.Name .root.Chart.Version }}
app.kubernetes.io/part-of: {{ .root.Chart.Name }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
app.kubernetes.io/version: {{ .root.Values.image.tag | quote }}
{{ include "shoplite.selectorLabels" . }}
{{- end }}

{{/*
Selector labels - must stay stable across upgrades.
*/}}
{{- define "shoplite.selectorLabels" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- end }}
