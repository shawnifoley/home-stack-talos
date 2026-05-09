.DEFAULT_GOAL := help

TOFU ?= tofu
ANSIBLE_PLAYBOOK ?= ansible-playbook
KUBECTL ?= kubectl

TOFU_DIR := tofu
ANSIBLE_DIR := ansible
K8S_ENV ?= prod
KUBECONFIG_DEV := $(HOME)/.kube/kubeconfig-dev.yaml
KUBECONFIG_PROD := $(HOME)/.kube/kubeconfig-prod.yaml
SLURM_SSH_PUBKEY_PATH ?= $(HOME)/.ssh/id_ed25519.pub

ifeq ($(K8S_ENV),dev)
KUBECONFIG_AUTO := $(KUBECONFIG_DEV)
else ifeq ($(K8S_ENV),prod)
KUBECONFIG_AUTO := $(KUBECONFIG_PROD)
else
$(error Invalid K8S_ENV='$(K8S_ENV)' (expected: dev or prod))
endif

KUBECONFIG ?= $(KUBECONFIG_AUTO)

DEV_STATE := terraform.dev.tfstate
PROD_STATE := terraform.prod.tfstate
DEV_VARS := variables.dev.tfvars
PROD_VARS := variables.prod.tfvars

.PHONY: help \
	tofu-init tofu-plan-dev tofu-apply-dev tofu-destroy-dev tofu-plan-prod tofu-apply-prod tofu-destroy-prod \
	bootstrap-dev bootstrap-prod postconfig-dev postconfig-prod \
	bootstrap-dev-check bootstrap-prod-check postconfig-dev-check postconfig-prod-check \
	talos-dev talos-prod ansible-dev ansible-prod \
	k8s-validate k8s-wait-ready k8s-apply-infra k8s-apply-media k8s-apply-prod \
	k8s-validate-slurm k8s-slurm-munge-secret k8s-slurm-ssh-key-secret k8s-slurm-munge-rotate k8s-apply-slurm k8s-delete-slurm

help:
	@echo "Targets:"
	@echo "< tofu | build VM's in proxmox >"
	@echo "    tofu-init"
	@echo "    tofu-plan-dev -> tofu-apply-dev | tofu-destroy-dev"
	@echo "    tofu-plan-prod -> tofu-apply-prod | tofu-destroy-prod"
	@echo "< ansible | bootstrap talos -> postconfig >"
	@echo "    bootstrap-dev -> postconfig-dev"
	@echo "    bootstrap-prod -> postconfig-prod"
	@echo "< ansible roles check >"
	@echo "    bootstrap-dev-check | bootstrap-prod-check"
	@echo "    postconfig-dev-check | postconfig-prod-check"
	@echo "< k8s | validate + deploy manifests >"
	@echo "    ( K8S_ENV=dev | K8S_ENV=prod )"
	@echo "    k8s-validate"
	@echo "    k8s-apply-infra -> k8s-wait-ready -> k8s-apply-media"
	@echo "    k8s-apply-prod (infra + wait + media)"
	@echo "< k8s | slurm playground >"
	@echo "    k8s-validate-slurm"
	@echo "    k8s-slurm-munge-secret"
	@echo "    k8s-slurm-ssh-key-secret (SLURM_SSH_PUBKEY_PATH=...)"
	@echo "    k8s-slurm-munge-rotate"
	@echo "    k8s-apply-slurm"
	@echo "    k8s-delete-slurm"

tofu-init:
	$(TOFU) -chdir=$(TOFU_DIR) init

tofu-plan-dev: tofu-init
	$(TOFU) -chdir=$(TOFU_DIR) plan -state=$(DEV_STATE) --var-file=$(DEV_VARS)

tofu-apply-dev: tofu-init
	$(TOFU) -chdir=$(TOFU_DIR) apply -state=$(DEV_STATE) --var-file=$(DEV_VARS)

tofu-destroy-dev: tofu-init
	$(TOFU) -chdir=$(TOFU_DIR) destroy -state=$(DEV_STATE) --var-file=$(DEV_VARS)

tofu-plan-prod: tofu-init
	$(TOFU) -chdir=$(TOFU_DIR) plan -state=$(PROD_STATE) --var-file=$(PROD_VARS)

tofu-apply-prod: tofu-init
	$(TOFU) -chdir=$(TOFU_DIR) apply -state=$(PROD_STATE) --var-file=$(PROD_VARS)

tofu-destroy-prod: tofu-init
	$(TOFU) -chdir=$(TOFU_DIR) destroy -state=$(PROD_STATE) --var-file=$(PROD_VARS)

bootstrap-dev:
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventory/dev/hosts.ini bootstrap.yml

bootstrap-prod:
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventory/prod/hosts.ini bootstrap.yml

postconfig-dev:
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventory/dev/hosts.ini postconfig.yml

postconfig-prod:
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventory/prod/hosts.ini postconfig.yml

bootstrap-dev-check:
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventory/dev/hosts.ini bootstrap.yml --syntax-check

bootstrap-prod-check:
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventory/prod/hosts.ini bootstrap.yml --syntax-check

postconfig-dev-check:
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventory/dev/hosts.ini postconfig.yml --syntax-check

postconfig-prod-check:
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventory/prod/hosts.ini postconfig.yml --syntax-check

# Backward-compatible aliases.
talos-dev: bootstrap-dev
talos-prod: bootstrap-prod
ansible-dev: postconfig-dev
ansible-prod: postconfig-prod

k8s-validate:
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) kustomize k8s/infra >/dev/null
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) kustomize k8s/media-stack >/dev/null

k8s-wait-ready:
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) cluster-info >/dev/null
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) wait --for=condition=Ready node --all --timeout=300s

k8s-apply-infra:
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) apply -k k8s/infra

k8s-apply-media: k8s-wait-ready
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) apply -k k8s/media-stack

k8s-apply-prod: k8s-apply-infra k8s-apply-media

k8s-validate-slurm:
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) kustomize k8s/slurm-stack >/dev/null

k8s-slurm-munge-secret:
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) -n slurm create namespace slurm --dry-run=client -o yaml | $(KUBECTL) --kubeconfig=$(KUBECONFIG) apply -f -
	@if ! $(KUBECTL) --kubeconfig=$(KUBECONFIG) -n slurm get secret munge-key >/dev/null 2>&1; then \
		$(KUBECTL) --kubeconfig=$(KUBECONFIG) -n slurm create secret generic munge-key --from-literal=munge.key="$$(openssl rand -base64 1024 | tr -d '\n')"; \
	else \
		echo "munge-key secret already exists; leaving it unchanged."; \
	fi

k8s-slurm-ssh-key-secret:
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) -n slurm create namespace slurm --dry-run=client -o yaml | $(KUBECTL) --kubeconfig=$(KUBECONFIG) apply -f -
	@test -f "$(SLURM_SSH_PUBKEY_PATH)" || (echo "Missing SSH public key: $(SLURM_SSH_PUBKEY_PATH)" && exit 1)
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) -n slurm create secret generic slurm-login-authorized-key \
		--from-file=authorized_key="$(SLURM_SSH_PUBKEY_PATH)" \
		--dry-run=client -o yaml | $(KUBECTL) --kubeconfig=$(KUBECONFIG) apply -f -

k8s-slurm-munge-rotate:
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) -n slurm create namespace slurm --dry-run=client -o yaml | $(KUBECTL) --kubeconfig=$(KUBECONFIG) apply -f -
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) -n slurm delete secret munge-key --ignore-not-found
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) -n slurm create secret generic munge-key --from-literal=munge.key="$$(openssl rand -base64 1024 | tr -d '\n')"
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) -n slurm rollout restart deploy/slurmctld deploy/slurmd deploy/slurm-login
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) -n slurm rollout status deploy/slurmctld
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) -n slurm rollout status deploy/slurmd
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) -n slurm rollout status deploy/slurm-login

k8s-apply-slurm: k8s-wait-ready k8s-slurm-munge-secret k8s-slurm-ssh-key-secret
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) apply -k k8s/slurm-stack

k8s-delete-slurm:
	$(KUBECTL) --kubeconfig=$(KUBECONFIG) delete -k k8s/slurm-stack
