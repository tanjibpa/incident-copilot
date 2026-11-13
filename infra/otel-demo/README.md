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
- Its own OpenTelemetry Collector.
- Bundled backends: Jaeger (traces), Prometheus (metrics), OpenSearch (logs) and Grafana.

The bundled backends are temporary. The next Phase 1 step replaces them with our own Prometheus, Loki and Tempo, and the agent's tools will query those.

## Overrides in `values.yaml`

- **`frontend-proxy` as NodePort 30080.** The kind config maps it to `localhost:8080`, so no port-forward is needed.
- **`ad` memory limit 300Mi → 500Mi.** At 300Mi the Java agent's startup was OOMKilled repeatedly. Spurious restarts would pollute the baseline that chaos scenarios are measured against.

## Usage

From the repo root:

```bash
make demo-up        # install and wait for every deployment to be Available (first run pulls images, ~3–5 min)
make demo-down      # uninstall the demo, keep the cluster
```

The chart doesn't support upgrades across versions. To change `CHART_VERSION`, run `make demo-down && make demo-up`. To change only `values.yaml` on the same version, use `helm upgrade` with the same `--version` and `--values`.

## Endpoints

| URL | What |
| --- | --- |
| http://localhost:8080 | Shop frontend |
| http://localhost:8080/grafana | Grafana (bundled) |
| http://localhost:8080/jaeger/ui | Jaeger (bundled) |
| http://localhost:8080/loadgen | Load generator (Locust) |
| http://localhost:8080/feature | flagd UI: built-in failure flags |

## Resources

The docs ask for about 6 GB of free RAM. On the reference machine (16 cores, 30 GB), the cluster plus the demo uses about 13 GB in total.

## Built-in failure flags

flagd can switch on failures that ship with the demo, for example payment failures, a memory leak and a slow ad service. They are cheap candidates for labeled incident scenarios alongside Chaos Mesh.
