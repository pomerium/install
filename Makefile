export CORE_VERSION=0.31.0
export ENTERPRISE_VERSION=0.31.1
export INGRESS_CONTROLLER_VERSION=0.31.0

.PHONY: update
update:
	./scripts/update

# Build and validate the Pomerium Zero plugin bundles; see zero/plugin/README.md.
.PHONY: zero-plugin
zero-plugin:
	$(MAKE) -C zero/plugin bundle
