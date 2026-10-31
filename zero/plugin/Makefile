# Builds and validates the Pomerium Zero plugin for the Anthropic and OpenAI
# plugin directories. README.md explains how to submit what this produces.

# Agent Plugins spec release whose JSON Schemas validate the OpenAI manifests.
# It must match the $schema URLs in openai/*.json; `make update-spec` bumps
# all three together.
AGENT_PLUGINS_SPEC_VERSION := 1.0.0

# Recursively expanded, so only the targets that use them need Node.js.
VERSION = $(shell node -p 'require("./claude/.claude-plugin/plugin.json").version')
OPENAI_VERSION = $(shell node -p 'require("./openai/plugin.json").version')
OPENAI_ZIP = dist/pomerium-zero-openai-$(VERSION).zip
SCHEMA_DIR := build/schemas/$(AGENT_PLUGINS_SPEC_VERSION)
OPENAI_DIR := build/openai

# Keep the pinned Claude Code CLI from updating itself or sending telemetry.
export DISABLE_AUTOUPDATER := 1
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC := 1

.PHONY: all
all: bundle

.PHONY: tools
tools: tools/node_modules/.package-lock.json

tools/node_modules/.package-lock.json: tools/package.json tools/package-lock.json
	npm --prefix tools ci --no-audit --no-fund

$(SCHEMA_DIR)/%.schema.json:
	mkdir -p $(@D)
	curl -fsSL -o $@ https://raw.githubusercontent.com/agentplugins/agent-plugins-spec/v$(AGENT_PLUGINS_SPEC_VERSION)/schemas/$(AGENT_PLUGINS_SPEC_VERSION)/$*.schema.json

.PHONY: validate
validate: validate-version validate-claude validate-openai

.PHONY: validate-version
validate-version:
	@test "$(VERSION)" = "$(OPENAI_VERSION)" || { echo "version mismatch: claude $(VERSION), openai $(OPENAI_VERSION)"; exit 1; }

.PHONY: validate-claude
validate-claude: tools
	tools/node_modules/.bin/claude plugin validate --strict claude

# The OpenAI bundle shares the README, license, and logo with the Claude
# plugin folder, which Anthropic reads from this repository directly.
.PHONY: stage-openai
stage-openai:
	rm -rf $(OPENAI_DIR)
	mkdir -p $(OPENAI_DIR)/assets
	cp openai/plugin.json openai/mcp.json claude/README.md claude/LICENSE $(OPENAI_DIR)/
	cp claude/assets/* openai/assets/* $(OPENAI_DIR)/assets/

.PHONY: validate-openai
validate-openai: tools stage-openai $(SCHEMA_DIR)/plugin.schema.json $(SCHEMA_DIR)/mcp.schema.json
	node tools/validate-openai-bundle.mjs $(OPENAI_DIR) $(SCHEMA_DIR)

.PHONY: bundle
bundle: validate
	mkdir -p dist
	rm -f $(OPENAI_ZIP)
	cd $(OPENAI_DIR) && zip -X -r -q $(CURDIR)/$(OPENAI_ZIP) .
	@echo "OpenAI bundle: $(OPENAI_ZIP)"

.PHONY: clean
clean:
	rm -rf build dist

.PHONY: update-spec
update-spec:
	@latest=$$(git ls-remote --tags --refs https://github.com/agentplugins/agent-plugins-spec 'v*' | sed 's|.*refs/tags/v||' | sort -V | tail -n 1); \
	echo "Agent Plugins spec: $(AGENT_PLUGINS_SPEC_VERSION) -> $$latest"; \
	sed -i.bak "s|^AGENT_PLUGINS_SPEC_VERSION := .*|AGENT_PLUGINS_SPEC_VERSION := $$latest|" Makefile; \
	sed -i.bak "s|agent-plugins.org/schemas/[^/]*/|agent-plugins.org/schemas/$$latest/|" openai/plugin.json openai/mcp.json; \
	rm -f Makefile.bak openai/*.bak
