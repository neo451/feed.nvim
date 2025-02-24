# Run all test files
test: deps/mini.nvim
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

# Run test from file at `$FILE` environment variable
test_file: deps/mini.nvim
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')"

# Download 'mini.nvim' to use its 'mini.test' testing module
deps/mini.nvim:
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/echasnovski/mini.nvim $@

doc: doc/feed.nvim.txt
	rm doc/feed.nvim.txt
	./panvimdoc.sh --project-name feed.nvim --input-file wiki/Usage-Guide.md --vim-version 0.11 --toc true --shift-heading-level-by -1
