#!/usr/bin/env bash
# Install our own telemetry backends (Prometheus, Loki, Tempo, Grafana)
# into the observability namespace of the local kind cluster.
# Idempotent: helm upgrade --install with pinned chart versions.
set -euo pipefail
cd "$(dirname "$0")"

NAMESPACE=observability
CONTEXT=kind-pager

# release  chart                              version
RELEASES=(
  "prometheus prometheus-community/prometheus 29.47.2"
  "loki       grafana-community/loki          21.2.1"
  "tempo      grafana-community/tempo         3.2.1"
  "grafana    grafana-community/grafana       14.4.1"
)

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update >/dev/null
helm repo add grafana-community https://grafana-community.github.io/helm-charts --force-update >/dev/null
helm repo update prometheus-community grafana-community >/dev/null

for entry in "${RELEASES[@]}"; do
  read -r release chart version <<<"$entry"
  echo "==> $release ($chart $version)"
  helm --kube-context "$CONTEXT" upgrade --install "$release" "$chart" \
    --version "$version" \
    --namespace "$NAMESPACE" --create-namespace \
    --values "$release-values.yaml" \
    --wait --timeout 10m
done

kubectl --context "$CONTEXT" -n "$NAMESPACE" get pods
echo "grafana: kubectl --context $CONTEXT -n $NAMESPACE port-forward svc/grafana 3000:80  ->  http://localhost:3000"
