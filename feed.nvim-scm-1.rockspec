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
   "tree-sitter-markdown",
   "tree-sitter-html",
   "tree-sitter-xml",
}

test_dependencies = {
   "lua >= 5.1",
   "nlua",
   "nui.nvim",
   "pathlib.nvim",
   "plenary.nvim",
   "tree-sitter-markdown",
   "tree-sitter-html",
   "tree-sitter-xml",
}
