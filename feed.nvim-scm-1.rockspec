rockspec_format = "3.0"
package = "feed.nvim"
version = "scm-1"

source = {
   url = "git+https://github.com/neo451/feed.nvim",
}

dependencies = {
   "lua >= 5.1",
   "nui.nvim",
   "pathlib.nvim",
   "plenary.nvim",
   "treedoc.nvim >= 1.0.3-1",
   -- "tree-sitter-markdown",
   -- "tree-sitter-markdown_inline",
   -- "tree-sitter-html",
   -- "tree-sitter-xml",
}

test_dependencies = {
   "lua >= 5.1",
   "nlua",
   "nui.nvim",
   "pathlib.nvim",
   "plenary.nvim",
   "treedoc.nvim >= 1.0.3-1",
   "tree-sitter-markdown",
   "tree-sitter-html",
   "tree-sitter-xml",
}
