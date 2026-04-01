LUARC = $(shell readlink -f .luarc.json)
TEST_ENV = XDG_CONFIG_HOME=$(CURDIR)/.test/config XDG_DATA_HOME=$(CURDIR)/.test/share XDG_STATE_HOME=$(CURDIR)/.test/state XDG_CACHE_HOME=$(CURDIR)/.test/cache

# Run all test files
test:
	$(TEST_ENV) nvim --headless --noplugin -u ./scripts/install_grammar.lua
	$(TEST_ENV) nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

# Run test from file at `$FILE` environment variable
test_file:
	$(TEST_ENV) nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')"

gen_doc:
	./panvimdoc.sh --project-name feed --input-file doc.md --vim-version 0.11 --shift-heading-level-by -1 --toc true 

types: ## Type check with lua-ls
	lua-language-server --configpath "$(LUARC)" --check lua/feed/

.PHONY: lint
lint: ## Lint the code with selene and typos
	selene --config selene/config.toml lua/ tests/
	# typos lua
