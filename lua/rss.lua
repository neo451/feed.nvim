local render = require "rss.render"
local config = require "rss.config"
local ut = require "rss.utils"
local actions = require "rss.actions"

local M = {}

local function prepare_bufs()
   render.buf = {
      index = vim.api.nvim_create_buf(false, true),
      entry = {},
   }
   for i = 1, 3 do
      render.buf.entry[i] = vim.api.nvim_create_buf(false, true)
      for rhs, lhs in pairs(config.keymaps.entry) do
         ut.push_keymap(render.buf.entry[i], lhs, actions.entry[rhs])
      end
   end
   for rhs, lhs in pairs(config.keymaps.index) do
      ut.push_keymap(render.buf.index, lhs, actions.index[rhs])
   end
end

---@param user_config rss.config
function M.setup(user_config)
   config.resolve(user_config)
   config.og_colorscheme = vim.cmd "colorscheme" --TODO:??
   prepare_bufs()

   vim.keymap.set("n", "<leader>rt", "<cmd>Telescope rss<cr>", { desc = "Show [R]ss feed in [T]elescope" })
   vim.keymap.set("n", "<leader>rs", render.show_index, { desc = "Show [R][s]s feed" })
end

return M
