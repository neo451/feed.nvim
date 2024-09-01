--- Default configuration.
--- Provides fallback values not specified in the user config.

---@alias rss.feed { name: string, tags: string[] } | string

---@class rss.config
---@field keymaps rss.keymap[]
local default = {
   date_format = "%Y-%m-%d",
   ---@alias rss.keymap table<string, string | function>
   keymaps = {
      ---@type rss.keymap
      index = {
         open_entry = "<CR>",
         open_split = "<M-CR>",
         open_browser = "b",
         open_w3m = "w",
         link_to_clipboard = "y",
         leave_index = "q",
         add_tag = "+",
         remove_tag = "-",
      },
      ---@type rss.keymap
      entry = {
         back_to_index = "q",
         next_entry = "}",
         prev_entry = "{",
      },
   },
   win_options = {
      conceallevel = 0,
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
   split = "13split",
   db_dir = "~/.rss.nvim.test",
   colorscheme = "kanagawa-lotus",
   max_title_length = 70,

   ---@type rss.feed[]
   feeds = {
      { "https://sspai.com/feed", name = "少数派", tags = { "tech" } },
      { "https://www.gcores.com/rss", name = "机核", tags = { "tech" } },
      "https://archlinux.org/feeds/news/",
      -- "https://andrewkelley.me/rss.xml",
      -- "https://feeds.bbci.co.uk/news/world/rss.xml",
   },
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
