#!/usr/bin/env bash
# Install the OpenTelemetry Demo into the local kind cluster.
# The chart does not support in-place upgrades, so a version change
# means: ./uninstall.sh && ./install.sh
set -euo pipefail
cd "$(dirname "$0")"

CHART_VERSION=0.42.6
RELEASE=otel-demo
NAMESPACE=otel-demo
CONTEXT=kind-pager

helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts --force-update >/dev/null
helm repo update open-telemetry >/dev/null

if helm --kube-context "$CONTEXT" status "$RELEASE" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "release $RELEASE already installed (chart $(helm --kube-context "$CONTEXT" list -n "$NAMESPACE" -f "^$RELEASE\$" -o json | sed -E 's/.*"chart":"([^"]+)".*/\1/'))"
else
  helm --kube-context "$CONTEXT" install "$RELEASE" open-telemetry/opentelemetry-demo \
    --version "$CHART_VERSION" \
    --namespace "$NAMESPACE" --create-namespace \
    --values values.yaml
fi

echo "waiting for deployments in $NAMESPACE..."
kubectl --context "$CONTEXT" -n "$NAMESPACE" wait deployment --all --for=condition=Available --timeout=600s
echo "shop:    http://localhost:8080"
echo "grafana: http://localhost:8080/grafana   jaeger: http://localhost:8080/jaeger/ui"
