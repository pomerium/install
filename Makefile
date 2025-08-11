export CORE_VERSION=0.30.3
export ENTERPRISE_VERSION=0.30.1
export INGRESS_CONTROLLER_VERSION=0.30.3

.PHONY: update
update:
	./scripts/update
