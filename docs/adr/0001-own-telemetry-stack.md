# 0001: Run our own telemetry stack instead of the OTel Demo's bundled backends

- Status: Accepted
- Date: 2026-11-13
- Phase: 1

## Context

The agent diagnoses incidents by querying metrics, logs and traces. Those backends are the contract between the target system and the agent's tools, and the eval harness depends on them staying stable across hundreds of runs.

The OpenTelemetry Demo chart bundles its own backends as subcharts: Jaeger for traces, Prometheus for metrics, OpenSearch for logs, and Grafana. The project plan calls for Prometheus, Loki and Tempo.

## Options

1. **Use the demo's bundled backends as they are.** This needs no extra work, but it means Jaeger and OpenSearch instead of Tempo and Loki. The agent's tools would query Jaeger's API and OpenSearch DSL, and both are less common in the SRE stacks the copilot is meant to resemble.
2. **Reconfigure the demo's subcharts.** Swapping subcharts isn't possible, because the demo chart only bundles Jaeger and OpenSearch. Even for Prometheus, its lifecycle would be tied to the demo release, and the demo chart doesn't support upgrades, so every version bump would wipe the telemetry.
3. **Run our own stack as separate releases in an `observability` namespace** (chosen). The demo only sends OTLP to it.

## Decision

Option 3. We install Prometheus, Loki, Tempo and Grafana as separate Helm releases with pinned versions (`infra/observability`). We turn off the demo's bundled backends and repoint its collector's exporters at our stack.

## Consequences

- The agent's tools (Phase 2) target fixed in-cluster endpoints, `prometheus`/`loki`/`tempo.observability.svc`, using PromQL, LogQL and TraceQL. The target system can be reinstalled, upgraded or eventually swapped without touching the tools or the evals.
- The demo can be torn down and reinstalled (`make demo-down demo-up`) while history stays in the backends. That's useful for "bad deploy" scenarios.
- The same releases deploy to GKE later with different values (object storage instead of the filesystem).
- We lose the demo's prebuilt Grafana dashboards, which are only created when its Grafana subchart is on. Dashboards for humans are Phase 7, and the agent doesn't need them.
- There are more charts to keep pinned and upgraded: four instead of one. The demo collector's config also has to track our endpoints in `infra/otel-demo/values.yaml`.
- Eval impact: none directly. This sets the query surface the Phase 2 baseline will be measured on, so changing it later would invalidate comparisons with earlier results.
