{{/*
Expand the name of the chart.
*/}}
{{- define "pomerium-zero.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pomerium-zero.fullname" -}}
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
{{- define "pomerium-zero.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pomerium-zero.labels" -}}
helm.sh/chart: {{ include "pomerium-zero.chart" . }}
{{ include "pomerium-zero.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pomerium-zero.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pomerium-zero.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Validate required values
*/}}
{{- define "pomerium-zero.validateValues" -}}
{{- if and (not .Values.existingSecret.name) (not .Values.pomeriumZeroToken) -}}
{{- fail "pomeriumZeroToken or existingSecret.name is required." -}}
{{- end -}}
{{- end -}}

{{/*
Secret name for the token
*/}}
{{- define "pomerium-zero.secretName" -}}
{{- with .Values.existingSecret.name -}}
{{- . -}}
{{- else -}}
{{- include "pomerium-zero.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Pod spec shared between Deployment and StatefulSet
*/}}
{{- define "pomerium-zero.podSpec" -}}
serviceAccountName: pomerium-zero
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
containers:
  - name: {{ .Chart.Name }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    env:
      - name: POMERIUM_ZERO_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ include "pomerium-zero.secretName" . }}
            key: {{ .Values.existingSecret.key }}
      - name: POMERIUM_NAMESPACE
        valueFrom:
          fieldRef:
            apiVersion: v1
            fieldPath: metadata.namespace
      - name: POD_IP
        valueFrom:
          fieldRef:
            fieldPath: status.podIP
      {{- if .Values.persistence.enabled }}
      - name: TMPDIR
        value: /tmp/pomerium
      - name: XDG_CACHE_HOME
        value: /tmp/pomerium/cache
      - name: XDG_DATA_HOME
        value: /data
      - name: BOOTSTRAP_CONFIG_FILE
        value: /data/bootstrap.dat
      - name: BOOTSTRAP_CONFIG_WRITEBACK_URI
        value: file:///data/bootstrap.dat
      {{- else }}
      - name: BOOTSTRAP_CONFIG_FILE
        value: "/var/run/secrets/pomerium/bootstrap.dat"
      - name: BOOTSTRAP_CONFIG_WRITEBACK_URI
        value: "secret://$(POMERIUM_NAMESPACE)/{{ include "pomerium-zero.secretName" . }}/bootstrap"
      - name: XDG_CACHE_HOME
        value: /tmp/pomerium/cache
      - name: XDG_DATA_HOME
        value: /tmp/pomerium/cache
      {{- end }}
      {{- with .Values.extraEnvVars }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
    ports:
      - containerPort: 443
        name: https
        protocol: TCP
      - containerPort: 9090
        name: metrics
        protocol: TCP
      - containerPort: 28080
        name: health
        protocol: TCP
    volumeMounts:
      - name: tmp
        mountPath: /tmp
      {{- if .Values.persistence.enabled }}
      - name: data
        mountPath: /data
      {{- else }}
      - name: bootstrap
        mountPath: /var/run/secrets/pomerium
        readOnly: true
      {{- end }}
      {{- with .Values.extraVolumeMounts }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
    resources:
      {{- toYaml .Values.resources | nindent 6 }}
    securityContext:
      {{- toYaml .Values.securityContext | nindent 6 }}
    startupProbe:
      httpGet:
        path: /startupz
        port: health
      initialDelaySeconds: 5
      timeoutSeconds: 1
      periodSeconds: 5
      successThreshold: 1
      failureThreshold: 60
    livenessProbe:
      httpGet:
        path: /healthz
        port: health
      timeoutSeconds: 1
      periodSeconds: 10
      successThreshold: 1
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /readyz
        port: health
      timeoutSeconds: 1
      periodSeconds: 10
      successThreshold: 1
      failureThreshold: 3
  {{- with .Values.extraContainers }}
  {{ toYaml . | nindent 2 }}
  {{- end }}
{{- with .Values.initContainers }}
initContainers:
  {{ toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if .Values.priorityClassName }}
priorityClassName: {{ .Values.priorityClassName | quote }}
{{- end }}
{{- if .Values.runtimeClassName }}
runtimeClassName: {{ .Values.runtimeClassName | quote }}
{{- end }}
volumes:
  - name: tmp
    emptyDir: {}
  {{- if not .Values.persistence.enabled }}
  - name: bootstrap
    secret:
      items:
      - key: bootstrap
        path: bootstrap.dat
      optional: true
      secretName: {{ include "pomerium-zero.secretName" . }}
  {{- end }}
  {{- with .Values.extraVolumes }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end -}}
