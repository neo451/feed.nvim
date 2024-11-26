--- Default configuration.
--- Provides fallback values not specified in the user config.

---@class feed._config
local default = {
   ---@type string
   db_dir = vim.fn.stdpath "data" .. "/feed",
   ---@type string
   -- colorscheme = vim.g.colorname,
   ---@type string
   date_format = "%Y-%m-%d",
   ---@type string
   split_cmd = "13split",
   ---@type boolean
   enable_default_keybindings = true,
   rsshub_instance = "https://rsshub.app",
   options = {
      ---@type table<string, any>
      index = {
         swapfile = false,
         undolevels = -1,
         undoreload = 0,
         conceallevel = 0,
         wrap = false,
         number = false,
         relativenumber = false,
         modifiable = false,
         listchars = "tab:> ,nbsp:+",
      },

      ---@type table<string, any>
      entry = {
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
         "date",
         width = 10,
         color = "Directory",
      },
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
         width = 80,
         color = "@markup.strong",
      },
      {
         "query",
         right = true,
         color = "Pmenu",
      },
   },

   search = {
      default_query = "@6-months-ago +unread",
   },

   ---@type feed.feed[]
   feeds = {},
   integrations = {
      telescope = {},
   },
   on_attach = function() end,
   progress = {
      "fidget",
      "notify",
      "mini",
      "native",
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
