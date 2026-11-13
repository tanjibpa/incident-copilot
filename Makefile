.PHONY: up-local down-local cluster-up demo-up demo-down

up-local: cluster-up demo-up ## Create the kind cluster and install the OTel Demo

down-local: ## Delete the local kind cluster (and everything in it)
	./infra/kind/down.sh

cluster-up: ## Create the local kind cluster
	./infra/kind/up.sh

demo-up: ## Install the OpenTelemetry Demo into the cluster
	./infra/otel-demo/install.sh

demo-down: ## Uninstall the OpenTelemetry Demo, keep the cluster
	./infra/otel-demo/uninstall.sh
