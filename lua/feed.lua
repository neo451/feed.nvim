local M = {}

vim.api.nvim_create_user_command("Feed", function(opts)
   local config = require "feed.config"
   require("feed.db").prepare_db(config.db_dir)

   local render = require "feed.render"
   local ut = require "feed.utils"
   local cmds = require("feed.commands").cmds

   render.prepare_bufs(cmds)

   if ut.check_command "Telescope" then
      pcall(require("telescope").load_extension, "feed")
   end

   if #opts.fargs == 0 then
      require("feed.commands").load_command { "show_index" }
   else
      require("feed.commands").load_command(opts.fargs)
   end
end, {
   nargs = "*",
   complete = function(_, line)
      local cmds_list = vim.tbl_keys(require("feed.commands").cmds)
      local l = vim.split(line, "%s+")
      return vim.tbl_filter(function(val)
         return vim.startswith(val, l[#l])
      end, cmds_list)
   end,
})

setmetatable(M, {
   __index = function(self, k)
      if not rawget(self, k) then
         return rawget(require("feed.commands").cmds, k)
      end
   end,
})

return M
