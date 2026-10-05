SHELL := /usr/bin/env bash

.DEFAULT_GOAL := help
PROJECT_NAME := feed.nvim

NVIM ?= nvim
VIMRUNTIME ?= $(shell $(NVIM) --clean --headless +'lua io.write(vim.env.VIMRUNTIME)' +q 2>/dev/null)

TEST_ENV := XDG_CONFIG_HOME=$(CURDIR)/.test/config XDG_DATA_HOME=$(CURDIR)/.test/share XDG_STATE_HOME=$(CURDIR)/.test/state XDG_CACHE_HOME=$(CURDIR)/.test/cache
TEST_SUITE_REPO := https://github.com/neo451/feed.nvim.test.suite
TEST_SUITE_DIR := $(CURDIR)/data
STYLUA_SOURCES := lua tests plugin scripts/install_grammar.lua scripts/minimal_init.lua minimal.lua lazy.lua

################################################################################
##@ Start here
.PHONY: chores
chores: style lint types test ## Run all local CI checks; pull requests should pass this.

################################################################################
##@ Development
.PHONY: lint
lint: ## Lint Lua and tests with Selene and typos
	selene --config selene/config.toml lua/ tests/
	typos --config _typos.toml lua/ tests/

.PHONY: style
style: ## Check Lua formatting with StyLua
	stylua --check $(STYLUA_SOURCES)

.PHONY: types
types: ## Type check with EmmyLua
	VIMRUNTIME=$(VIMRUNTIME) emmylua_check ./lua/ --config .emmyrc.json
	# TODO: Enable --warnings-as-errors after the legacy type warnings are resolved.

.PHONY: test
test: test_data ## Run the test suite
	$(TEST_ENV) $(NVIM) --headless --noplugin -u ./scripts/install_grammar.lua
	$(TEST_ENV) $(NVIM) --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

.PHONY: test_file
test_file: test_data ## Run the test file specified by FILE
	$(TEST_ENV) $(NVIM) --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')"

.PHONY: test_data
test_data:
	@if [ -d "$(TEST_SUITE_DIR)/.git" ]; then \
		git -C "$(TEST_SUITE_DIR)" pull --ff-only; \
	elif [ ! -e "$(TEST_SUITE_DIR)" ]; then \
		git clone "$(TEST_SUITE_REPO)" "$(TEST_SUITE_DIR)"; \
	else \
		printf '%s\n' '$(TEST_SUITE_DIR) exists and is not a git checkout'; \
		exit 1; \
	fi

################################################################################
##@ Documentation
# TODO: Revisit and modernize documentation generation in a separate follow-up.
.PHONY: gen_doc
gen_doc: ## Generate Vim documentation with panvimdoc (legacy)
	./panvimdoc.sh --project-name feed --input-file doc.md --vim-version 0.11 --shift-heading-level-by -1 --toc true

################################################################################
##@ Helpers
.PHONY: help
help: ## Display this help
	@echo "Welcome to $$(tput bold)$(PROJECT_NAME)$$(tput sgr0)"
	@echo ""
	@echo "To get started:"
	@echo "  >>> $$(tput bold)make chores$$(tput sgr0)"
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
