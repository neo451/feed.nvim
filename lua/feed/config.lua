--- Default configuration.
--- Provides fallback values not specified in the user config.

---@class feed._config
local default = {
   ---@type string
   db_dir = vim.fn.stdpath "data" .. "/feed",
   ---@type string
   colorscheme = "morning",
   ---@type string
   date_format = "%Y-%m-%d",

   index = {
      ---@type table<string, string | function>
      keys = {
         ["<CR>"] = "show_entry",
         ["<M-CR>"] = "show_in_split",
         ["+"] = "tag",
         ["-"] = "untag",
         ["?"] = "which_key",
         s = "search",
         b = "show_in_browser",
         w = "show_in_w3m",
         r = "refresh",
         y = "link_to_clipboard",
         q = "quit_index",
      },
      ---@type table<string, any>
      opts = {
         conceallevel = 0,
         wrap = false,
         number = false,
         relativenumber = false,
         modifiable = false,
         listchars = "tab:> ,nbsp:+",
         -- listchars = { tab = "» ", trail = "·", nbsp = "␣" },
      },
   },

   entry = {
      ---@type table<string, string | function>
      keys = {
         ["<CR>"] = "show_entry",
         ["}"] = "show_next",
         ["{"] = "show_prev",
         ["?"] = "which_key",
         ["+"] = "tag",
         ["-"] = "untag",
         u = "urlview",
         gx = "open_url",
         q = "quit_entry",
      },
      ---@type table<string, any>
      opts = {
         conceallevel = 3,
         concealcursor = "nvc",
         wrap = true,
         number = false,
         relativenumber = false,
         modifiable = false,
         filetype = "markdown",
      },
   },
   ---@type table<string, any>
   layout = {
      -- TODO: validate
      {
         "feed",
         width = 25,
         color = "Title",
      },
      {
         "tags",
         width = 25,
         color = "WhiteSpace",
      },
      {
         "title",
         right_justify = false,
         width = 80,
         color = "@markup.strong",
      },
      -- date = {
      --    format = "%Y-%m-%d",
      --    width = 10,
      -- },
      ---@type string
      split = "13split",
      header = "Hint: <M-CR> open in split | <CR> open | + add tag | - remove tag | ? help", -- TODO: placeholder set to nil
   },

   search = {
      default_query = "@6-months-ago +unread",
   },

   ---@type feed.feed[]
   feeds = {},
   integrations = {
      telescope = {},
      zenmode = {
         window = {
            width = 0.85, -- width will be 85% of the editor width
         },
         -- callback where you can add custom code when the Zen window opens
         on_open = function(win) end,
         -- callback where you can add custom code when the Zen window closes
         on_close = function() end,
      },
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

--- Merge the user configuration with the default values.
---@param config feed.config
function M.resolve(config)
   config = config or {}
   M.config = vim.tbl_deep_extend("keep", config, default)
end

return M
