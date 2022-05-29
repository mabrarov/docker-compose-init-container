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
Application pod main container image tag.
*/}}
{{- define "app.mainContainer.image.tag" -}}
{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}

{{/*
Application pod main container image full name.
*/}}
{{- define "app.mainContainer.image.fullName" -}}
{{ printf "%s/%s:%s" .Values.image.registry .Values.image.name (include "app.mainContainer.image.tag" . ) }}
{{- end }}

{{/*
Application pod init container image tag.
*/}}
{{- define "app.initContainer.image.tag" -}}
{{ .Values.init.image.tag | default .Chart.AppVersion }}
{{- end }}

{{/*
Application pod init container image full name.
*/}}
{{- define "app.initContainer.image.fullName" -}}
{{ printf "%s/%s:%s" .Values.init.image.registry .Values.init.image.name (include "app.initContainer.image.tag" . ) }}
{{- end }}

{{/*
Test pod init container image tag.
*/}}
{{- define "app.testContainer.image.tag" -}}
{{ .Values.test.image.tag | default "latest" }}
{{- end }}

{{/*
Test pod init container image full name.
*/}}
{{- define "app.testContainer.image.fullName" -}}
{{ printf "%s/%s:%s" .Values.test.image.registry .Values.test.image.name (include "app.testContainer.image.tag" . ) }}
{{- end }}

{{/*
Name of test image pull secret.
*/}}
{{- define "app.testImagePullSecretName" -}}
{{ include "app.fullname" . }}-test-pull
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
