LUARC = $(shell readlink -f .luarc.json)

# Run all test files
test: deps/mini.nvim deps/nvim-treesitter
	nvim --headless --noplugin -u ./scripts/install_grammar.lua
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

# Run test from file at `$FILE` environment variable
test_file: deps/mini.nvim
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')"

# Download 'mini.nvim' to use its 'mini.test' testing module
deps/mini.nvim:
	git clone https://github.com/neo451/feed.nvim.test.suite.git data/
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/echasnovski/mini.nvim $@

# Download 'mini.nvim' to use its 'mini.test' testing module
deps/nvim-treesitter:
	git clone --filter=blob:none https://github.com/nvim-treesitter/nvim-treesitter.git --branch main $@

gen_doc:
	./panvimdoc.sh --project-name feed --input-file doc.md --vim-version 0.11 --shift-heading-level-by -1 --toc true 

types: ## Type check with lua-ls
	lua-language-server --configpath "$(LUARC)" --check lua/feed/
