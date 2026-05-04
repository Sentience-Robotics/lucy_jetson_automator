# Initial Jenkins controller bootstrap: Ansible over SSH from your machine to the VPS only (never localhost).
# Other automation (Jetson apply, tuning, pipelines) is configured on the instance, in Jenkins, or in
# hardcoded repo configs — not via this Makefile.

-include .env
export

.DEFAULT_GOAL := help

##@ Help

.PHONY: help
help: ## Show available targets
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

##@ Jenkins bootstrap

.PHONY: validate-env-vps
validate-env-vps: ## Check required VPS_* and VPS_SSH_* (remote-only) from .env
	@echo "Validating VPS bootstrap environment..."
	@if [ -z "$(VPS_SSH_HOST)" ] || [ -z "$(VPS_SSH_USER)" ]; then \
		echo "Error: VPS_SSH_HOST and VPS_SSH_USER must be set in .env (remote SSH bootstrap only)."; \
		exit 1; \
	fi
	@if [ "$(VPS_CONFIGURE_FIREWALL)" = "false" ]; then \
		echo "Firewall skipped (VPS_CONFIGURE_FIREWALL=false)."; \
	fi
	@if [ -z "$(VPS_CONTROLLER_REPO_URL)" ]; then \
		echo "Warning: VPS_CONTROLLER_REPO_URL empty — Jenkins jobs need CONTROLLER_REPO_URL in /opt/lucy-infra/jenkins/.env"; \
	fi
	@if [ -z "$(VPS_JENKINS_DOCKER_SOCK_GID)" ]; then \
		echo "Warning: VPS_JENKINS_DOCKER_SOCK_GID unset — bootstrap defaults to 991; set to match: stat -c '%g' /var/run/docker.sock on the VPS."; \
	fi
	@echo "VPS environment validation passed"

.PHONY: ansible-collections
ansible-collections: ## Install Ansible Galaxy collections (run once on the machine that runs bootstrap-jenkins)
	cd ansible && ansible-galaxy collection install -r requirements.yml

.PHONY: bootstrap-jenkins
bootstrap-jenkins: validate-env-vps ## Run vps-bootstrap playbook over SSH to VPS_SSH_HOST
	@$(CURDIR)/bootstrap-vps.sh
