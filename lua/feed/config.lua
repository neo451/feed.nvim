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
   -- TODO: one opts
   index = {
      ---@type table<string, any>
      opts = {
         conceallevel = 0,
         wrap = false,
         number = false,
         relativenumber = false,
         modifiable = false,
         listchars = "tab:> ,nbsp:+",
      },
   },

   entry = {
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
         on_open = function() end,
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
