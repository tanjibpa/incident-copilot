# infra/observability

Our own telemetry backends. The OTel Demo's collector sends traces, metrics and logs here, and in Phase 2 the agent's read-only tools will query these endpoints. Why we run our own instead of the demo's bundled backends: [ADR 0001](../../docs/adr/0001-own-telemetry-stack.md).

## What it installs

All four go into the `observability` namespace, with chart versions pinned in `install.sh`:

| Release | Chart | Version | Role |
| --- | --- | --- | --- |
| `prometheus` | `prometheus-community/prometheus` | 29.47.2 (Prometheus v3.16) | Metrics. Gets OTLP from the collector and scrapes kube-state-metrics, node-exporter and cAdvisor |
| `loki` | `grafana-community/loki` | 21.2.1 (Loki 3.7) | Logs, monolithic mode with filesystem storage. Gets OTLP at `/otlp` |
| `tempo` | `grafana-community/tempo` | 3.2.1 (Tempo 3.1) | Traces, single binary with local storage. Gets OTLP on 4317/4318 |
| `grafana` | `grafana-community/grafana` | 14.4.1 (Grafana 13.3) | UI, with Prometheus/Loki/Tempo datasources and trace↔log↔metric links provisioned |

The Grafana and Tempo charts in the old `grafana/` repo are deprecated, and the maintained ones now live in `grafana-community`.

Storage is ephemeral (no PVCs) with short retention: Prometheus 7d, Loki and Tempo 72h. Data is lost when a pod restarts, which is fine for local runs because every eval scenario starts from a fresh fault anyway.

## Data flow

```
OTel Demo services ──OTLP──▶ otel-collector-agent (otel-demo ns)
                                 ├─ traces  ─▶ tempo:4317
                                 ├─ metrics ─▶ prometheus:9090/api/v1/otlp
                                 └─ logs    ─▶ loki:3100/otlp
kube-state-metrics, node-exporter, kubelet/cAdvisor ◀── scraped by prometheus
```

## Usage

From the repo root:

```bash
make obs-up         # install or upgrade all four (idempotent; helm upgrade --install --wait)
make obs-down       # uninstall them and delete the namespace
```

`make up-local` installs this stack before the demo. If you're converting a cluster that still runs the demo's bundled backends, upgrade the demo first (`helm upgrade` with `infra/otel-demo/values.yaml`). Otherwise the bundled Prometheus's `ClusterRole/prometheus` collides with ours.

## Endpoints

These are in-cluster addresses, which is what the agent will use:

| Backend | Address | Query language |
| --- | --- | --- |
| Prometheus | `http://prometheus.observability.svc:9090` | PromQL |
| Loki | `http://loki.observability.svc:3100` | LogQL |
| Tempo | `http://tempo.observability.svc:3200` | TraceQL |
| Grafana | `http://grafana.observability.svc:80` | n/a |

From your machine:

```bash
kubectl -n observability port-forward svc/grafana 3000:80        # http://localhost:3000 (anonymous admin)
kubectl -n observability port-forward svc/prometheus 9090:9090
```

## Quick checks

```bash
# PromQL: services emitting span metrics
curl -s 'localhost:9090/api/v1/query?query=count(count by (service_name)(traces_span_metrics_calls_total))'
# PromQL: container restarts in the demo (should be flat at baseline)
curl -s 'localhost:9090/api/v1/query?query=sum(increase(kube_pod_container_status_restarts_total{namespace="otel-demo"}[10m]))'
```

In Grafana Explore, try `{service_name="checkout"}` on Loki and `{resource.service.name="checkout" && status=error}` on Tempo.

## Resources

The four backends add about 3 GB of RAM. Each has a 1Gi memory limit, except Grafana at 512Mi.
