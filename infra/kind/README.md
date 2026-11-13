# infra/kind

The local Kubernetes cluster for Incident Copilot. Everything in Phases 1–4 and 6 runs here, so no cloud account is needed.

## What it creates

A [kind](https://kind.sigs.k8s.io) cluster named `pager` (kubectl context `kind-pager`):

| Node | Role |
| --- | --- |
| `pager-control-plane` | API server, etcd, scheduler |
| `pager-worker` | Workloads |
| `pager-worker2` | Workloads |

- Every node uses `kindest/node:v1.37.0`, pinned by digest to the image published with kind v0.33.0.
- There are two workers so Chaos Mesh scenarios can stress or partition one node without taking down the control plane.
- Port mapping: NodePort `30080` on the control plane maps to `127.0.0.1:8080` on the host. The OTel Demo's `frontend-proxy` uses it (see [`../otel-demo`](../otel-demo)).

## Prerequisites

| Tool | Tested version |
| --- | --- |
| Docker Engine | 29.x (your user must be in the `docker` group) |
| kind | v0.33.0 |
| kubectl | v1.37.2 |
| helm | v4.3.1 |

Raise the inotify limits, or multi-node kind clusters hit "too many open files" ([kind known issues](https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files)):

```bash
printf 'fs.inotify.max_user_watches=524288\nfs.inotify.max_user_instances=512\n' | sudo tee /etc/sysctl.d/99-kind.conf && sudo sysctl --system
```

## Usage

From the repo root:

```bash
make cluster-up     # create the cluster only (idempotent)
make up-local       # create the cluster and install the OTel Demo
make down-local     # delete the cluster and everything in it
```

`up.sh` checks that the tools exist, that the Docker daemon is reachable and that the inotify limits are high enough, then runs `kind create cluster`. It does nothing if the cluster already exists.

## Checking the cluster

```bash
kind get clusters
kubectl get nodes -o wide
kubectl get pods -A
kind export logs ./kind-logs --name pager          # kubelet/containerd/control-plane logs from every node
docker exec -it pager-worker crictl ps              # containers on one node
```

`kind-logs/` is gitignored.

## Troubleshooting

- **`docker daemon not reachable`**: your shell doesn't have the `docker` group yet. Log out and back in, or run `newgrp docker` in that terminal.
- **Port 8080 already in use**: something on the host holds `127.0.0.1:8080`. Stop it, or change `hostPort` in `kind-config.yaml` and recreate the cluster.
