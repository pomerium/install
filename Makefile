export CORE_VERSION=0.30.5
export ENTERPRISE_VERSION=0.30.4
export INGRESS_CONTROLLER_VERSION=0.30.5

.PHONY: update
update:
	./scripts/update
