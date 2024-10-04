--- Default configuration.
--- Provides fallback values not specified in the user config.

---@class feed._config
local default = {
   ---@type string
   db_dir = "~/.local/share/nvim/feed",
   ---@type table<table, table<string, string | function>>
   keymaps = {
      index = {
         show_entry = "<CR>",
         show_in_split = "<M-CR>",
         show_in_browser = "b",
         show_in_w3m = "w",
         link_to_clipboard = "y",
         quit_index = "q",
         tag = "+",
         untag = "-",
         which_key = "?",
      },
      entry = {
         show_index = "q",
         show_next = "}",
         show_prev = "{",
         which_key = "?",
      },
   },
   ---@type table<string, any>
   win_options = {
      conceallevel = 0,
      wrap = true,
   },
   ---@type table<string, any>
   buf_options = {
      filetype = "markdown", -- TODO: rss?
      modifiable = false,
   },
   ---@type table<string, any>
   search = {
      sort_order = "descending",
      update_hook = {},
      filter = "@6-months-ago +unread",
   },
   ---@type table<string, any>
   layout = {
      title = {
         right_justify = false,
         width = 70,
      },
      date = {
         format = "%Y-%m-%d",
         width = 10,
      },
   },
   ---@type string
   split = "13split",
   ---@type string
   colorscheme = "morning",

   ---@type feed.feed[]
   feeds = {},

   ---@type string
   opml = "~/.local/share/nvim/feed/feeds.opml",
}

---@class feed.config
---@field feed? feed.feed[]
---@field opml? string

---@type feed.config
local config = vim.tbl_deep_extend("force", default, vim.g.feed_config or {})

return config
