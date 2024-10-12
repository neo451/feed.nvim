--- Default configuration.
--- Provides fallback values not specified in the user config.

---@class feed._config
local default = {
   ---@type string
   db_dir = "~/.local/share/nvim/feed",
   ---@type { index : table<string, string | function>, entry : table<string, string | function> }
   keymaps = {
      index = {
         ["<CR>"] = "show_entry",
         ["<M-CR>"] = "show_in_split",
         ["+"] = "tag",
         ["-"] = "untag",
         ["?"] = "which_key",
         b = "show_in_browser",
         w = "show_in_w3m",
         r = "refresh",
         y = "link_to_clipboard",
         q = "quit_index",
      },
      entry = {
         ["}"] = "show_next",
         ["{"] = "show_prev",
         ["?"] = "which_key",
         u = "urlview",
         q = "quite_entry",
      },
   },
   ---@type table<string, any>
   win_options = {
      conceallevel = 0,
      wrap = true,
   },
   ---@type table<string, any>
   buf_options = {
      filetype = "markdown", -- TODO: FeedBuffer?
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
      ---@type string
      split = "13split",
      header = "show_hint", -- TODO: placeholder set to nil
   },
   ---@type string
   colorscheme = "morning",

   ---@type feed.feed[]
   feeds = {},

   ---@type boolean
   zenmode = false,
}

---@type feed.config | nil
vim.g.feed = vim.g.feed

---@type feed.config
local config = vim.tbl_deep_extend("force", default, vim.g.feed or {})

return config
