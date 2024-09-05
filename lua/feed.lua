local render = require "feed.render"
local config = require "feed.config"
local ut = require "feed.utils"
local cmds = require("feed.commands").cmds

local M = {}

local function prepare_bufs()
   render.buf = {
      index = vim.api.nvim_create_buf(false, true),
      entry = {},
   }
   for i = 1, 3 do
      render.buf.entry[i] = vim.api.nvim_create_buf(false, true)
      for rhs, lhs in pairs(config.keymaps.entry) do
         ut.push_keymap(render.buf.entry[i], lhs, cmds[rhs])
      end
   end
   for rhs, lhs in pairs(config.keymaps.index) do
      ut.push_keymap(render.buf.index, lhs, cmds[rhs])
   end
end

---@param user_config feed.config
function M.setup(user_config)
   config.resolve(user_config)
   config.og_colorscheme = vim.cmd "colorscheme" --TODO:??
   prepare_bufs()

   vim.keymap.set("n", "<leader>rs", render.show_index, { desc = "Show [R][s]s feed" })
   if ut.check_command "Telescope" then
      local ok = pcall(require("telescope").load_extension, "feed")
      print(ok)
      vim.keymap.set("n", "<leader>rt", "<cmd>Telescope feed<cr>", { desc = "Show [R]ss feed in [T]elescope" })
   end
end

local ok, err = pcall(require("telescope").load_extension, "feed")
print(err)
return M
