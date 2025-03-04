# Run all test files
test: deps/mini.nvim
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

# Run test from file at `$FILE` environment variable
test_file: deps/mini.nvim
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')"

# Download 'mini.nvim' to use its 'mini.test' testing module
deps/mini.nvim:
	git clone https://github.com/neo451/feed.nvim.test.suite.git data/
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/echasnovski/mini.nvim $@

gen_doc:
	./panvimdoc.sh --project-name feed --input-file README.md --vim-version 0.11 --shift-heading-level-by -1 --toc true 

gen_site:
	pandoc --katex --from markdown+tex_math_single_backslash --to html5+smart --template="./scripts/template.html5" --css="./theme.css" --css="./skylighting-solarized-theme.css" --toc --wrap=none --metadata title="feed.nvim" README.md --lua-filter=scripts/include-files.lua --lua-filter=scripts/skip-blocks.lua -t html -o docs/index.html
