-- TODO: move to utils and use in health
local function ts_backend()
   local use_nts = pcall(require, "nvim-treesitter")
   if use_nts then
      return vim.cmd.TSInstall
   end
   local use_rock = pcall(require, "rock")
   if use_rock then
      return function(parser)
         vim.cmd.Rock("install", "tree-sitter-" .. parser)
      end
   end
   return false
end

local function check_treesitter_parser(name)
   local res, _ = pcall(vim.treesitter.language.inspect, name)
   return res
end

local function build()
   local cmd = ts_backend()
   if not cmd then
      error "[feed.nvim]: Build failed: no available tree-sitter backend found, use nvim-treesitter or rocks.nvim"
   end
   for _, v in ipairs { "xml", "html", "markdown" } do
      if not check_treesitter_parser(v) then
         pcall(cmd, v)
      end
   end
end

return { build = build }
