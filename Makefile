# Makefile for NVIDIA Jetson AGX Orin Ansible Setup
-include .env
export

# Docker and Ansible settings
DOCKER_IMAGE_NAME = jetson-ansible
CONTAINER_NAME = jetson-ansible-runner
ANSIBLE_DIR = ./ansible

# Default target
.DEFAULT_GOAL := help

##@ General Commands

.PHONY: help
help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup & Initialization

.PHONY: init
init: build-if-needed requirements-if-needed ## Initialize project (build Docker image, install requirements)
	@echo "🚀 Project initialization complete!"
	@echo "📝 Next: Create .env file with your Jetson configuration"

.PHONY: setup
setup: validate-env ## Run complete Jetson setup with optimized architecture
	@echo "Running Jetson setup with optimized architecture..."
	docker run --rm \
		--name $(CONTAINER_NAME) \
		-v $(PWD)/$(ANSIBLE_DIR):/ansible \
		-v $(PWD)/.env:/ansible/.env \
		-v ~/.ssh:/home/ansible/.ssh:ro \
		--env-file .env \
		-w /ansible \
		$(DOCKER_IMAGE_NAME) \
		ansible-playbook -i inventory/hosts.yml playbooks/jetson-setup.yml -vvv

.PHONY: setup-performance
setup-performance: validate-env ## Run performance optimization only (jetson-optimization role)
	@echo "Configuring Jetson performance optimization..."
	docker run --rm \
		--name $(CONTAINER_NAME) \
		-v $(PWD)/$(ANSIBLE_DIR):/ansible \
		-v $(PWD)/.env:/ansible/.env \
		-v ~/.ssh:/home/ansible/.ssh:ro \
		--env-file .env \
		-w /ansible \
		$(DOCKER_IMAGE_NAME) \
		ansible-playbook -i inventory/hosts.yml playbooks/jetson-setup.yml --tags jetson,performance -v

.PHONY: ping
ping: validate-env ## Test connection to Jetson device
	@echo "Testing connection to Jetson device..."
	docker run --rm \
		--name $(CONTAINER_NAME) \
		-v $(PWD)/$(ANSIBLE_DIR):/ansible \
		-v $(PWD)/.env:/ansible/.env \
		-v ~/.ssh:/home/ansible/.ssh:ro \
		--env-file .env \
		-w /ansible \
		$(DOCKER_IMAGE_NAME) \
		ansible -i inventory/hosts.yml jetson -m ping

##@ Docker Management

.PHONY: build
build: ## Build the Ansible Docker image
	@echo "Building Ansible Docker image..."
	docker build -t $(DOCKER_IMAGE_NAME) .

.PHONY: build-if-needed
build-if-needed: ## Build Docker image only if files changed
	@echo "Checking if Docker image needs rebuilding..."
	@if [ ! "$$(docker images -q $(DOCKER_IMAGE_NAME) 2> /dev/null)" ] || \
	   [ requirements.txt -nt "$$(docker inspect --format='{{.Created}}' $(DOCKER_IMAGE_NAME) 2>/dev/null || echo '1970-01-01T00:00:00Z')" ] || \
	   [ Dockerfile -nt "$$(docker inspect --format='{{.Created}}' $(DOCKER_IMAGE_NAME) 2>/dev/null || echo '1970-01-01T00:00:00Z')" ]; then \
		echo "Docker image needs rebuilding..."; \
		$(MAKE) build; \
	else \
		echo "Docker image is up to date."; \
	fi

.PHONY: shell
shell: validate-env ## Start interactive shell in Ansible container
	@echo "Starting interactive shell..."
	docker run --rm -it \
		--name $(CONTAINER_NAME) \
		-v $(PWD)/$(ANSIBLE_DIR):/ansible \
		-v $(PWD)/.env:/ansible/.env \
		-v ~/.ssh:/home/ansible/.ssh:ro \
		--env-file .env \
		$(DOCKER_IMAGE_NAME) \
		/bin/bash

.PHONY: clean
clean: ## Remove Docker containers and images
	@echo "Cleaning up Docker resources..."
	-docker rm -f $(CONTAINER_NAME) 2>/dev/null || true
	-docker rmi $(DOCKER_IMAGE_NAME) 2>/dev/null || true

##@ Specialized Setup

.PHONY: setup-hostname
setup-hostname: validate-env ## Configure hostname only (requires JETSON_HOSTNAME in .env)
	@echo "Configuring hostname..."
	docker run --rm \
		--name $(CONTAINER_NAME) \
		-v $(PWD)/$(ANSIBLE_DIR):/ansible \
		-v $(PWD)/.env:/ansible/.env \
		-v ~/.ssh:/home/ansible/.ssh:ro \
		--env-file .env \
		-w /ansible \
		$(DOCKER_IMAGE_NAME) \
		ansible-playbook -i inventory/hosts.yml playbooks/jetson-setup.yml --tags hostname -v

.PHONY: setup-wifi
setup-wifi: validate-env ## Configure WiFi only (requires WIFI_SSID and WIFI_PASSWORD in .env)
	@echo "Configuring WiFi connection..."
	docker run --rm \
		--name $(CONTAINER_NAME) \
		-v $(PWD)/$(ANSIBLE_DIR):/ansible \
		-v $(PWD)/.env:/ansible/.env \
		-v ~/.ssh:/home/ansible/.ssh:ro \
		--env-file .env \
		-w /ansible \
		$(DOCKER_IMAGE_NAME) \
		ansible-playbook -i inventory/hosts.yml playbooks/jetson-setup.yml --tags wifi -v

.PHONY: setup-check
setup-check: validate-env ## Run setup in check mode (dry run)
	@echo "Running setup in check mode..."
	docker run --rm \
		--name $(CONTAINER_NAME) \
		-v $(PWD)/$(ANSIBLE_DIR):/ansible \
		-v $(PWD)/.env:/ansible/.env \
		-v ~/.ssh:/home/ansible/.ssh:ro \
		--env-file .env \
		-w /ansible \
		$(DOCKER_IMAGE_NAME) \
		ansible-playbook -i inventory/hosts.yml playbooks/jetson-setup.yml --check -v

##@ Utilities

.PHONY: requirements
requirements: ## Install Ansible requirements
	@echo "Installing Ansible requirements..."
	docker run --rm \
		--name $(CONTAINER_NAME) \
		-v $(PWD)/$(ANSIBLE_DIR):/ansible \
		-w /ansible \
		$(DOCKER_IMAGE_NAME) \
		ansible-galaxy install -r requirements.yml

.PHONY: requirements-force
requirements-force: ## Force reinstall Ansible requirements
	@echo "Force installing Ansible requirements..."
	docker run --rm \
		--name $(CONTAINER_NAME) \
		-v $(PWD)/$(ANSIBLE_DIR):/ansible \
		-w /ansible \
		$(DOCKER_IMAGE_NAME) \
		ansible-galaxy install -r requirements.yml --force

.PHONY: requirements-if-needed
requirements-if-needed: ## Install requirements only if requirements.yml changed or collections missing
	@echo "Checking if Ansible requirements need to be installed..."
	@REQUIREMENTS_HASH=$$(md5sum ansible/requirements.yml 2>/dev/null | cut -d' ' -f1); \
	LAST_HASH_FILE=".requirements_hash"; \
	if [ ! -f "$$LAST_HASH_FILE" ] || [ "$$(cat $$LAST_HASH_FILE 2>/dev/null)" != "$$REQUIREMENTS_HASH" ]; then \
		echo "Requirements need to be installed..."; \
		$(MAKE) requirements && echo "$$REQUIREMENTS_HASH" > "$$LAST_HASH_FILE"; \
	else \
		echo "Requirements are up to date."; \
	fi

.PHONY: validate-env
validate-env: ## Validate .env file configuration
	@echo "Validating environment configuration..."
	@if [ ! -f .env ]; then \
		echo "Error: .env file not found. Create it from the README template."; \
		exit 1; \
	fi
	@if [ -z "$(JETSON_HOST)" ]; then \
		echo "Error: JETSON_HOST not set in .env"; \
		exit 1; \
	fi
	@if [ -z "$(JETSON_USER)" ]; then \
		echo "Error: JETSON_USER not set in .env"; \
		exit 1; \
	fi
	@echo "✅ Environment validation passed!" 