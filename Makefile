export CORE_VERSION=0.31.0
export ENTERPRISE_VERSION=0.31.1
export INGRESS_CONTROLLER_VERSION=0.31.0

.PHONY: update
update:
	./scripts/update
