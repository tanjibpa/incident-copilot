#!/usr/bin/env bash
# Create the local kind cluster. Idempotent: does nothing if it already exists.
set -euo pipefail
cd "$(dirname "$0")"
CLUSTER=pager

for bin in docker kind kubectl helm; do
  command -v "$bin" >/dev/null || { echo "missing: $bin" >&2; exit 1; }
done
docker info >/dev/null 2>&1 || { echo "docker daemon not reachable (is your user in the docker group?)" >&2; exit 1; }

watches=$(sysctl -n fs.inotify.max_user_watches)
instances=$(sysctl -n fs.inotify.max_user_instances)
if (( watches < 524288 || instances < 512 )); then
  echo "warning: inotify limits are low (watches=$watches instances=$instances); multi-node kind may hit 'too many open files'." >&2
  echo "         see https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files" >&2
fi

if kind get clusters | grep -qx "$CLUSTER"; then
  echo "cluster $CLUSTER already exists"
else
  kind create cluster --config kind-config.yaml --wait 120s
fi
kubectl cluster-info --context "kind-$CLUSTER"
kubectl get nodes -o wide
