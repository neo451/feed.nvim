local M = {}

vim.api.nvim_create_user_command("Feed", function(opts)
   local render = require "feed.render"
   local cmds = require "feed.commands"

   render.prepare_bufs(cmds)

   ---@param args string[]
   local function load_command(args)
      local cmd = table.remove(args, 1)
      if type(cmds[cmd]) == "table" then
         return cmds[cmd].impl(unpack(args))
      elseif type(cmds[cmd]) == "function" then
         return cmds[cmd](unpack(args))
      end
   end

   pcall(require("telescope").load_extension, "feed")

   if #opts.fargs == 0 then
      load_command { "show_index" }
   else
      load_command(opts.fargs)
   end
end, {
   nargs = "*",
   complete = function(_, line)
      local cmds_list = vim.tbl_keys(require "feed.commands")
      local l = vim.split(line, "%s+")
      return vim.tbl_filter(function(val)
         return vim.startswith(val, l[#l])
      end, cmds_list)
   end,
})

---@param config feed.config
M.setup = function(config)
   vim.g.feed = config
end

setmetatable(M, {
   __index = function(self, k)
      if not rawget(self, k) then
         return rawget(require "feed.commands", k)
      end
   end,
})

return M
