{{- define "blog-chart.blogDeployLabels" }}
app: app-1
{{- end }}

{{- define "blog-chart.blogAppLabels" }}
app: app-1
version: "1.0"
{{- end }}

{{- define "blog-chart.nginxDeployLabels" }}
app: app-1-nginx
{{- end }}

{{- define "blog-chart.nginxAppLabels" }}
app: app-1-nginx
{{- end }}

{{- define "blog-chart.staticAppDeployLabels" }}
app: app-2
{{- end }}

{{- define "blog-chart.staticAppLabels" }}
app: app-2
version: "1.0"
{{- end }}

{{- define "blog-chart.dbDeployLabels" }}
app: postgres
{{- end }}

{{- define "blog-chart.dbAppLabels" }}
app: postgres
{{- end }}