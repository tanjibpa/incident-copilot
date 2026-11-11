.PHONY: up-local down-local

up-local: ## Create the local kind cluster (more of the stack lands here during Phase 1)
	./infra/kind/up.sh

down-local: ## Delete the local kind cluster
	./infra/kind/down.sh
