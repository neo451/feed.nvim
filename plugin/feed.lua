local config = require "feed.config"
require("feed.db").check_dir(config.db_dir)

-- TODO: enough for now, very few actions
vim.api.nvim_create_user_command("Feed", function(opts)
   if #opts.fargs == 0 then
      require("feed.render").show_index()
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
