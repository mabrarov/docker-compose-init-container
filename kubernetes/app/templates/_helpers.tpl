{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . | quote }}
{{ include "app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end }}

{{/*
Name of deployment.
*/}}
{{- define "app.deploymentName" -}}
{{ include "app.fullname" . }}
{{- end }}

{{/*
Name of service.
*/}}
{{- define "app.serviceName" -}}
{{ include "app.fullname" . }}
{{- end }}

{{/*
Name of ingress.
*/}}
{{- define "app.ingressName" -}}
{{ include "app.fullname" . }}
{{- end }}

{{/*
Name of TLS secret.
*/}}
{{- define "app.tlsSecretName" -}}
{{ include "app.fullname" . }}-tls
{{- end }}

{{/*
Name of application secret.
*/}}
{{- define "app.secretName" -}}
{{ include "app.fullname" . }}
{{- end }}

{{/*
Name of test pod.
*/}}
{{- define "app.testPodName" -}}
{{ include "app.fullname" . }}-test-connection
{{- end }}

{{/*
Name of container port.
*/}}
{{- define "app.containerPortName" -}}
http
{{- end }}

{{/*
Scheme to access application endpoint.
*/}}
{{- define "app.portScheme" -}}
http
{{- end }}

{{/*
Name of service port.
*/}}
{{- define "app.servicePortName" -}}
http
{{- end }}

{{/*
Space separated JVM options/
*/}}
{{- define "app.finalJvmOptions" -}}
{{- $first := true }}
{{- range .Values.app.defaultJvmOptions }}
{{- if $first }}{{- $first = false }}{{- else }} {{ end -}}{{ . }}{{- end }}
{{- range .Values.app.extraJvmOptions }}
{{- if $first }}{{- $first = false }}{{- else }} {{ end -}}{{ . }}{{- end }}
{{- end }}
