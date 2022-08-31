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
Selector labels
*/}}
{{- define "app.matchLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . | quote }}
{{ include "app.matchLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
{{- end }}

{{/*
Component labels
*/}}
{{- define "app.componentLabels" -}}
app.kubernetes.io/component: "app"
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
Name of image pull secret.
*/}}
{{- define "app.imagePullSecretName" -}}
{{ include "app.fullname" . }}-pull
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
{{- define "app.test.podName" -}}
{{ include "app.fullname" . }}-test
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
Application main container image tag.
*/}}
{{- define "app.mainContainer.imageTag" -}}
{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}

{{/*
Application main container image full name.
*/}}
{{- define "app.mainContainer.imageFullName" -}}
{{ printf "%s/%s:%s" .Values.image.registry .Values.image.name (include "app.mainContainer.imageTag" . ) }}
{{- end }}

{{/*
Application init container image tag.
*/}}
{{- define "app.initContainer.imageTag" -}}
{{ .Values.init.image.tag | default .Chart.AppVersion }}
{{- end }}

{{/*
Application init container image full name.
*/}}
{{- define "app.initContainer.imageFullName" -}}
{{ printf "%s/%s:%s" .Values.init.image.registry .Values.init.image.name (include "app.initContainer.imageTag" . ) }}
{{- end }}

{{/*
Test component labels
*/}}
{{- define "app.test.componentLabels" -}}
app.kubernetes.io/component: "test"
{{- end }}

{{/*
Test container image tag.
*/}}
{{- define "app.test.imageTag" -}}
{{ .Values.test.image.tag | default "latest" }}
{{- end }}

{{/*
Test container image full name.
*/}}
{{- define "app.test.imageFullName" -}}
{{ printf "%s/%s:%s" .Values.test.image.registry .Values.test.image.name (include "app.test.imageTag" . ) }}
{{- end }}

{{/*
Name of test image pull secret.
*/}}
{{- define "app.test.imagePullSecretName" -}}
{{ include "app.fullname" . }}-test-pull
{{- end }}

{{/*
Space separated JVM options
*/}}
{{- define "app.finalJvmOptions" -}}
{{- $first := true }}
{{- range .Values.app.defaultJvmOptions }}
{{- if $first }}{{- $first = false }}{{- else }} {{ end -}}{{ . }}{{- end }}
{{- range .Values.app.extraJvmOptions }}
{{- if $first }}{{- $first = false }}{{- else }} {{ end -}}{{ . }}{{- end }}
{{- end }}

{{/*
Docker authentication config for image registry.
{{ include "app.dockerRegistryAuthenticationConfig" (dict "imageRegistry" .Values.image.registry "credentials" .Values.image.pull.secret) }}
*/}}
{{- define "app.dockerRegistryAuthenticationConfig" -}}
{{- $registry := .imageRegistry }}
{{- $username := .credentials.username }}
{{- $password := .credentials.password }}
{{- $email := .credentials.email }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" $registry $username $password $email (printf "%s:%s" $username $password | b64enc) | b64enc }}
{{- end }}

{{/*
Renders a value that contains template.
Usage:
{{ include "app.tplValuesRender" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "app.tplValuesRender" -}}
{{- if typeIs "string" .value }}
{{- tpl .value .context }}
{{- else }}
{{- tpl (.value | toYaml) .context }}
{{- end }}
{{- end -}}
