LUARC = $(shell readlink -f .luarc.json)
TEST_ENV = XDG_CONFIG_HOME=$(CURDIR)/.test/config XDG_DATA_HOME=$(CURDIR)/.test/share XDG_STATE_HOME=$(CURDIR)/.test/state XDG_CACHE_HOME=$(CURDIR)/.test/cache
TEST_SUITE_REPO = https://github.com/neo451/feed.nvim.test.suite
TEST_SUITE_DIR = $(CURDIR)/data

test_data:
	@if [ -d "$(TEST_SUITE_DIR)/.git" ]; then \
		git -C "$(TEST_SUITE_DIR)" pull --ff-only; \
	elif [ ! -e "$(TEST_SUITE_DIR)" ]; then \
		git clone "$(TEST_SUITE_REPO)" "$(TEST_SUITE_DIR)"; \
	else \
		printf '%s\n' '$(TEST_SUITE_DIR) exists and is not a git checkout'; \
		exit 1; \
	fi

# Run all test files
test: test_data
	$(TEST_ENV) nvim --headless --noplugin -u ./scripts/install_grammar.lua
	$(TEST_ENV) nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

# Run test from file at `$FILE` environment variable
test_file: test_data
	$(TEST_ENV) nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')"

gen_doc:
	./panvimdoc.sh --project-name feed --input-file doc.md --vim-version 0.11 --shift-heading-level-by -1 --toc true 

types: ## Type check with lua-ls
	lua-language-server --configpath "$(LUARC)" --check lua/feed/

.PHONY: lint test test_file test_data
lint: ## Lint the code with selene and typos
	selene --config selene/config.toml lua/ tests/
	# typos lua
