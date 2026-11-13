# infra/otel-demo

The target system: the [OpenTelemetry Demo](https://opentelemetry.io/docs/demo/), a microservices shop that the copilot diagnoses. It runs on the local kind cluster from [`../kind`](../kind).

## What it installs

| | |
| --- | --- |
| Chart | `open-telemetry/opentelemetry-demo` **0.42.6** (pinned in `install.sh`) |
| Release / namespace | `otel-demo` / `otel-demo` |
| Overrides | `values.yaml` |

The chart installs:

- About 15 microservices written in several languages.
- Kafka, Valkey and Postgres.
- A load generator that drives shopper traffic continuously.
- flagd for feature flags.
- Its own OpenTelemetry Collector (a DaemonSet, `otel-collector-agent`).

The chart's bundled backends (Jaeger, Prometheus, OpenSearch, Grafana) are turned off. The collector exports to our own stack in [`../observability`](../observability) instead: see [ADR 0001](../../docs/adr/0001-own-telemetry-stack.md).

## Overrides in `values.yaml`

- **`frontend-proxy` as NodePort 30080.** The kind config maps it to `localhost:8080`, so no port-forward is needed.
- **Bundled backends off**, and the collector's pipelines repointed: traces → Tempo (OTLP gRPC), metrics → Prometheus (`/api/v1/otlp`), logs → Loki (`/otlp`). The chart's Jaeger and OpenSearch exporters stay defined but unused, because `null` doesn't reliably delete subchart defaults in Helm.
- **`kubeletstats` with `insecure_skip_verify`.** kind's kubelet serving certs have no IP SANs, so without this the collector never gets pod and container resource metrics. Local only.
- **`ad` and `fraud-detection` memory limits 300Mi → 500Mi.** Both are JVM services with the Java agent. At 300Mi, `ad` was OOMKilled during startup and `fraud-detection` was OOMKilled 265 times over two idle days. Spurious restarts would pollute the baseline that chaos scenarios are measured against.

## Usage

From the repo root:

```bash
make demo-up        # install and wait for every deployment to be Available (first run pulls images, ~3–5 min)
                    # install ../observability first (make up-local does both, in order)
make demo-down      # uninstall the demo, keep the cluster
```

The chart doesn't support upgrades across versions. To change `CHART_VERSION`, run `make demo-down && make demo-up`. To change only `values.yaml` on the same version, use `helm upgrade` with the same `--version` and `--values`.

## Endpoints

| URL | What |
| --- | --- |
| http://localhost:8080 | Shop frontend |
| http://localhost:8080/loadgen | Load generator (Locust) |
| http://localhost:8080/feature | flagd UI: built-in failure flags |

Grafana, Prometheus, Loki and Tempo are in the `observability` namespace (see [`../observability`](../observability)).

## Resources

The docs ask for about 6 GB of free RAM. On the reference machine (16 cores, 30 GB), the cluster, the demo and the observability stack use about 16 GB in total.

## Built-in failure flags

flagd can switch on failures that ship with the demo, for example payment failures, a memory leak and a slow ad service. They are cheap candidates for labeled incident scenarios alongside Chaos Mesh.
