# Run all test files
test: build
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

build: deps/mini.nvim
	nvim --headless --noplugin -u ./scripts/deps.lua

# Run test from file at `$FILE` environment variable
test_file: build
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')"

# Download 'mini.nvim' to use its 'mini.test' testing module
deps/mini.nvim:
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/echasnovski/mini.nvim $@
