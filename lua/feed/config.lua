--- Default configuration.
--- Provides fallback values not specified in the user config.

---@alias rss.feed { name: string, tags: string[] } | string

---@class rss.config
---@field keymaps rss.keymap[]
local default = {
   db_dir = "~/.local/share/nvim/feed",
   date_format = "%Y-%m-%d",
   ---@alias rss.keymap table<string, string | function>
   keymaps = {
      ---@type rss.keymap
      index = {
         show_entry = "<CR>",
         show_in_split = "<M-CR>",
         show_in_browser = "b",
         show_in_w3m = "w",
         link_to_clipboard = "y",
         quit_index = "q",
         tag = "+",
         untag = "-",
      },
      ---@type rss.keymap
      entry = {
         show_index = "q",
         show_next = "}",
         show_prev = "{",
      },
   },
   win_options = {
      conceallevel = 0,
      wrap = true,
   },
   buf_options = {
      filetype = "markdown", -- TODO: rss?
      modifiable = false,
   },
   search = {
      sort_order = "descending",
      update_hook = {},
      filter = "@6-months-ago +unread",
   },
   titles = {
      right_justify = false,
      max_length = 70,
   },
   split = "13split",
   colorscheme = "kanagawa-lotus",

   ---@type rss.feed[]
   feeds = {},
}

local M = {}

setmetatable(M, {
   __index = function(self, key)
      local config = rawget(self, "config")
      if config then
         return config[key]
      end
      return default[key]
   end,
})

-- local function prepare_db()
if vim.fn.isdirectory(M.db_dir) == 0 then
   local path = vim.fn.expand(M.db_dir)
   vim.fn.mkdir(path, "p")
end
-- end

--- Merge the user configuration with the default values.
---@param config table<string, any> user configuration
function M.resolve(config)
   config = config or {}
   M.config = vim.tbl_deep_extend("keep", config, default)
end

return M
