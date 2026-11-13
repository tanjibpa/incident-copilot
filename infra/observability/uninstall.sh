#!/usr/bin/env bash
set -euo pipefail
for release in grafana tempo loki prometheus; do
  helm --kube-context kind-pager uninstall "$release" -n observability --ignore-not-found
done
kubectl --context kind-pager delete namespace observability --ignore-not-found
