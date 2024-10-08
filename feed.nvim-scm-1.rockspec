rockspec_format = "3.0"
package = "feed.nvim"
version = "scm-1"

source = {
   url = "git+https://github.com/neo451/feed.nvim",
}

test_dependencies = {
   "lua >= 5.1",
   "nlua",
   "plenary.nvim",
   "treedoc.nvim",
   "tree-sitter-markdown",
   "tree-sitter-markdown_inline",
   "tree-sitter-html",
   "tree-sitter-xml",
}
