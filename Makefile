SHELL := /bin/bash
ENV ?= dev
TF_DIR := terraform/environments/$(ENV)

.PHONY: help check-tools init fmt lint validate terraform-validate k8s-validate test security plan deploy destroy build
help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "%-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
check-tools: ## Report required and optional local tools
	@./scripts/check-tools.sh
init: ## Initialize Terraform without the remote backend
	terraform -chdir=$(TF_DIR) init -backend=false
fmt: ## Format Terraform and Python
	terraform fmt -recursive terraform
	python3 -m ruff format src tests
lint: ## Check Python and Terraform formatting
	python3 -m ruff check src tests
	terraform fmt -check -recursive terraform
terraform-validate: init ## Validate the selected Terraform environment
	terraform -chdir=$(TF_DIR) validate
k8s-validate: ## Build overlays and validate Kubernetes schemas
	@for environment in dev stage prod; do kubectl kustomize gitops/$$environment | kubeconform -strict -summary -ignore-missing-schemas; done
validate: lint terraform-validate k8s-validate ## Run all static validation
test: ## Run Python unit tests
	python3 -m pytest -q
security: ## Scan IaC, secrets, and container configuration
	checkov -d terraform -d kubernetes --quiet
	trivy config --severity HIGH,CRITICAL --exit-code 1 .
	gitleaks detect --no-git --source .
plan: terraform-validate ## Create a Terraform plan for ENV
	terraform -chdir=$(TF_DIR) plan -out=tfplan
deploy: terraform-validate ## Apply Terraform for ENV
	terraform -chdir=$(TF_DIR) apply
destroy: terraform-validate ## Destroy Terraform resources for ENV
	terraform -chdir=$(TF_DIR) destroy
build: ## Build the model-server container
	docker build --tag model-server:local .
