export CORE_TAG=v0.30.3
export ENTERPRISE_TAG=v0.30.1
export INGRESS_CONTROLLER_TAG=v0.30.3

.PHONY: update
update:
	./scripts/update
