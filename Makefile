.DEFAULT_GOAL := help

TOFU ?= tofu
ANSIBLE_PLAYBOOK ?= ansible-playbook

TOFU_DIR := tofu
ANSIBLE_DIR := ansible

DEV_STATE := terraform.dev.tfstate
PROD_STATE := terraform.prod.tfstate
DEV_VARS := variables.dev.tfvars
PROD_VARS := variables.prod.tfvars

.PHONY: help \
	tofu-init tofu-plan-dev tofu-apply-dev tofu-destroy-dev tofu-plan-prod tofu-apply-prod tofu-destroy-prod \
	bootstrap-dev bootstrap-prod postconfig-dev postconfig-prod \
	bootstrap-dev-check bootstrap-prod-check postconfig-dev-check postconfig-prod-check \
	talos-dev talos-prod ansible-dev ansible-prod

help:
	@echo "Targets:"
	@echo "  tofu-init"
	@echo "  tofu-plan-dev | tofu-apply-dev | tofu-destroy-dev"
	@echo "  tofu-plan-prod | tofu-apply-prod | tofu-destroy-prod"
	@echo "  bootstrap-dev | bootstrap-prod"
	@echo "  postconfig-dev | postconfig-prod"
	@echo "  bootstrap-dev-check | bootstrap-prod-check"
	@echo "  postconfig-dev-check | postconfig-prod-check"

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
