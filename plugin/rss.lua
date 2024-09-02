local config = require "rss.config"
require("rss.db").check_dir(config.db_dir)

-- TODO: enough for now, very few actions
vim.api.nvim_create_user_command("Rss", function(opts)
   if #opts.fargs == 0 then
      require("rss.render").show_index()
   else
      require("rss.commands").load_command(opts.fargs)
   end
end, {
   nargs = "*",
   complete = function(_, line)
      local cmds_list = vim.tbl_keys(require("rss.commands").cmds)
      local l = vim.split(line, "%s+")
      return vim.tbl_filter(function(val)
         return vim.startswith(val, l[#l])
      end, cmds_list)
   end,
})
