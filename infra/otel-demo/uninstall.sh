#!/usr/bin/env bash
set -euo pipefail
helm --kube-context kind-pager uninstall otel-demo -n otel-demo --ignore-not-found
kubectl --context kind-pager delete namespace otel-demo --ignore-not-found
