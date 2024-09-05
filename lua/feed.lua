local render = require "feed.render"
local config = require "feed.config"
local ut = require "feed.utils"
local cmds = require("feed.commands").cmds

local M = {}

---@param user_config feed.config
function M.setup(user_config)
   config.resolve(user_config)
   config.og_colorscheme = vim.g.colors_name
   render.prepare_bufs(cmds)

   vim.keymap.set("n", "<leader>rs", render.show_index, { desc = "Show [R][s]s feed" })
   if ut.check_command "Telescope" then
      pcall(require("telescope").load_extension, "feed")
      vim.keymap.set("n", "<leader>rt", "<cmd>Telescope feed<cr>", { desc = "Show [R]ss feed in [T]elescope" })
   end

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
end

return M
