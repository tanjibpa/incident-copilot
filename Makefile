.PHONY: up-local down-local cluster-up obs-up obs-down demo-up demo-down

up-local: cluster-up obs-up demo-up ## Cluster, then telemetry backends, then the OTel Demo

down-local: ## Delete the local kind cluster (and everything in it)
	./infra/kind/down.sh

cluster-up: ## Create the local kind cluster
	./infra/kind/up.sh

obs-up: ## Install Prometheus, Loki, Tempo and Grafana into the observability namespace
	./infra/observability/install.sh

obs-down: ## Uninstall the observability stack, keep the cluster
	./infra/observability/uninstall.sh

demo-up: ## Install the OpenTelemetry Demo into the cluster
	./infra/otel-demo/install.sh

demo-down: ## Uninstall the OpenTelemetry Demo, keep the cluster
	./infra/otel-demo/uninstall.sh
