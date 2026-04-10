#!/usr/bin/env bash
# Unit tests for pomerium-zero Helm chart
# Requires: helm, yq
set -euo pipefail

CHART_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
TESTS=0

pass() { TESTS=$((TESTS + 1)); echo "  PASS: $1"; }
fail() { TESTS=$((TESTS + 1)); FAILURES=$((FAILURES + 1)); echo "  FAIL: $1"; echo "        $2"; }

assert_eq() {
  local desc="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then pass "$desc"
  else fail "$desc" "got '$got', want '$want'"; fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if echo "$haystack" | grep -qF "$needle"; then pass "$desc"
  else fail "$desc" "output does not contain '$needle'"; fi
}

assert_not_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if ! echo "$haystack" | grep -qF "$needle"; then pass "$desc"
  else fail "$desc" "output should not contain '$needle'"; fi
}

# Helper: render template and select documents by kind
render() { helm template test "$CHART_DIR" --set pomeriumZeroToken=test-token "$@" 2>&1; }
select_kind() { echo "$1" | yq -N 'select(.kind == "'"$2"'")'; }

# ─── StatefulSet (persistence enabled, default) ──────────────────────

echo "Suite: StatefulSet (persistence enabled)"

out="$(render)"
ss="$(select_kind "$out" "StatefulSet")"

assert_eq "renders StatefulSet" "$(echo "$ss" | yq '.kind')" "StatefulSet"
assert_eq "serviceName matches fullname" "$(echo "$ss" | yq '.spec.serviceName')" "test-pomerium-zero"
assert_eq "replicas default 1" "$(echo "$ss" | yq '.spec.replicas')" "1"
assert_eq "PVC name is data" "$(echo "$ss" | yq '.spec.volumeClaimTemplates[0].metadata.name')" "data"
assert_eq "PVC size is 1Gi" "$(echo "$ss" | yq '.spec.volumeClaimTemplates[0].spec.resources.requests.storage')" "1Gi"
assert_eq "PVC access mode" "$(echo "$ss" | yq '.spec.volumeClaimTemplates[0].spec.accessModes[0]')" "ReadWriteOnce"
assert_eq "no storageClassName by default" "$(echo "$ss" | yq '.spec.volumeClaimTemplates[0].spec.storageClassName')" "null"

# Env vars
container="$(echo "$ss" | yq '.spec.template.spec.containers[0]')"
assert_contains "env BOOTSTRAP_CONFIG_FILE" "$container" "/data/bootstrap.dat"
assert_contains "env BOOTSTRAP_CONFIG_WRITEBACK_URI" "$container" "file:///data/bootstrap.dat"
assert_contains "env XDG_DATA_HOME" "$container" "/data"
assert_contains "env TMPDIR" "$container" "/tmp/pomerium"
assert_contains "volumeMount /data" "$container" "mountPath: /data"
assert_not_contains "no bootstrap secret mount" "$container" "/var/run/secrets/pomerium"

# No Deployment should be rendered
assert_eq "no Deployment rendered" "$(select_kind "$out" "Deployment" | yq '.kind')" "null"

# No Role/RoleBinding
assert_eq "no Role rendered" "$(select_kind "$out" "Role" | yq '.kind')" "null"
assert_eq "no RoleBinding rendered" "$(select_kind "$out" "RoleBinding" | yq '.kind')" "null"

# ServiceAccount always present
sa="$(select_kind "$out" "ServiceAccount")"
assert_eq "ServiceAccount rendered" "$(echo "$sa" | yq '.kind')" "ServiceAccount"

echo ""

# ─── Custom persistence settings ─────────────────────────────────────

echo "Suite: Custom persistence settings"

out="$(render --set persistence.size=10Gi --set persistence.storageClass=gp3)"
ss="$(select_kind "$out" "StatefulSet")"

assert_eq "custom PVC size" "$(echo "$ss" | yq '.spec.volumeClaimTemplates[0].spec.resources.requests.storage')" "10Gi"
assert_eq "custom storageClassName" "$(echo "$ss" | yq '.spec.volumeClaimTemplates[0].spec.storageClassName')" "gp3"

echo ""

# ─── Custom replicas ─────────────────────────────────────────────────

echo "Suite: Custom replicas"

out="$(render --set replicaCount=3)"
ss="$(select_kind "$out" "StatefulSet")"
assert_eq "replicas 3" "$(echo "$ss" | yq '.spec.replicas')" "3"

echo ""

# ─── Deployment (persistence disabled) ───────────────────────────────

echo "Suite: Deployment (persistence disabled)"

out="$(render --set persistence.enabled=false)"
dep="$(select_kind "$out" "Deployment")"

assert_eq "renders Deployment" "$(echo "$dep" | yq '.kind')" "Deployment"
assert_eq "no StatefulSet" "$(select_kind "$out" "StatefulSet" | yq '.kind')" "null"

container="$(echo "$dep" | yq '.spec.template.spec.containers[0]')"
assert_contains "env BOOTSTRAP_CONFIG_FILE secret path" "$container" "/var/run/secrets/pomerium/bootstrap.dat"
assert_contains "env BOOTSTRAP_CONFIG_WRITEBACK_URI secret://" "$container" "secret://\$(POMERIUM_NAMESPACE)/test-pomerium-zero/bootstrap"
assert_contains "env XDG_DATA_HOME /tmp" "$container" "/tmp/pomerium/cache"
assert_contains "bootstrap volume mount" "$container" "/var/run/secrets/pomerium"
assert_not_contains "no /data mount" "$container" "mountPath: /data"

# RBAC should include Role + RoleBinding
assert_eq "Role rendered" "$(select_kind "$out" "Role" | yq '.kind')" "Role"
assert_eq "RoleBinding rendered" "$(select_kind "$out" "RoleBinding" | yq '.kind')" "RoleBinding"

echo ""

# ─── Service ─────────────────────────────────────────────────────────

echo "Suite: Service"

out="$(render)"
svc="$(select_kind "$out" "Service")"

assert_eq "Service type LoadBalancer" "$(echo "$svc" | yq '.spec.type')" "LoadBalancer"
assert_eq "Service port 443" "$(echo "$svc" | yq '.spec.ports[0].port')" "443"

out="$(render --set service.type=NodePort --set service.nodePort=30443)"
svc="$(select_kind "$out" "Service")"
assert_eq "NodePort type" "$(echo "$svc" | yq '.spec.type')" "NodePort"
assert_eq "nodePort 30443" "$(echo "$svc" | yq '.spec.ports[0].nodePort')" "30443"

echo ""

# ─── Image configuration ─────────────────────────────────────────────

echo "Suite: Image"

out="$(render --set image.repository=custom/pomerium --set image.tag=v1.0.0)"
ss="$(select_kind "$out" "StatefulSet")"
assert_eq "custom image" "$(echo "$ss" | yq '.spec.template.spec.containers[0].image')" "custom/pomerium:v1.0.0"

echo ""

# ─── Namespace ────────────────────────────────────────────────────────

echo "Suite: Namespace"

out="$(render -n pomerium-zero)"
ns="$(select_kind "$out" "Namespace")"
assert_eq "creates Namespace by default" "$(echo "$ns" | yq '.kind')" "Namespace"
assert_eq "namespace name matches release namespace" "$(echo "$ns" | yq '.metadata.name')" "pomerium-zero"

out="$(render -n pomerium-zero --set createNamespace=false)"
ns="$(select_kind "$out" "Namespace")"
assert_eq "no Namespace when createNamespace=false" "$(echo "$ns" | yq '.kind')" "null"

echo ""

# ─── Existing Secret ──────────────────────────────────────────────────

echo "Suite: Existing Secret"

out="$(helm template test "$CHART_DIR" --set existingSecret.name=my-secret --set existingSecret.key=my-key 2>&1)"

# No Secret resource should be rendered
assert_eq "no Secret rendered" "$(select_kind "$out" "Secret" | yq '.kind')" "null"

# secretKeyRef should point to the existing secret
ss="$(select_kind "$out" "StatefulSet")"
container="$(echo "$ss" | yq '.spec.template.spec.containers[0]')"
assert_contains "secretRef name is my-secret" "$container" "name: my-secret"
assert_contains "secretRef key is my-key" "$container" "key: my-key"

# Default mode should still create a Secret
out="$(render)"
secret="$(select_kind "$out" "Secret")"
assert_eq "Secret rendered by default" "$(echo "$secret" | yq '.kind')" "Secret"

echo ""

# ─── Validation ──────────────────────────────────────────────────────

echo "Suite: Validation"

validation_output="$(helm template test "$CHART_DIR" --set 'pomeriumZeroToken=' 2>&1 || true)"
if echo "$validation_output" | grep -q "pomeriumZeroToken or existingSecret.name is required"; then
  pass "fails when neither token nor existingSecret set"
else
  fail "fails when neither token nor existingSecret set" "expected validation error"
fi

# Should succeed with existingSecret alone
validation_output="$(helm template test "$CHART_DIR" --set 'pomeriumZeroToken=' --set existingSecret.name=my-secret 2>&1 || true)"
if echo "$validation_output" | grep -q "Error"; then
  fail "succeeds with existingSecret.name" "expected no error"
else
  pass "succeeds with existingSecret.name"
fi

echo ""

# ─── Summary ─────────────────────────────────────────────────────────

echo "─────────────────────────────────"
echo "Tests: $TESTS  Passed: $((TESTS - FAILURES))  Failed: $FAILURES"

if [ "$FAILURES" -gt 0 ]; then
  exit 1
fi
