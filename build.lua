local function check_treesitter_parser(name)
   local res, _ = pcall(vim.treesitter.language.inspect, name)
   return res
end

local has_ts = pcall(require, "nvim-treesitter")
if not has_ts then
   error "[feed.nvim]: Build failed: no available tree-sitter backend found, use nvim-treesitter or rocks.nvim"
end

if not check_treesitter_parser "xml" then
   pcall(vim.cmd.TSInstall, "xml")
end
