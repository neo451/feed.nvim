---@class feed.config
---@field feeds? string | { name: string, tags: table }
---@field colorscheme? string
---@field db_dir? string
---@field date_format? string
---@field curl_params? string[]
---@field rsshub_instance? string move all options here as a enum??
---@field layout? table
---@field progress? { backend: "mini.notify" | "snacks" | "notify" | "fidget" | "native" }
---@field search? { backend: "telescope" | "mini.pick" | "fzf-lua", default_query: string }
---@field data? { backend: "local" | "ttrss" }
---@field options? table

---@class feed._config
local default = {
   ---@type string
   db_dir = vim.fn.stdpath("data") .. "/feed",
   ---@type string
   colorscheme = vim.g.colorname,
   ---@type string
   date_format = "%Y-%m-%d",
   ---@type string
   rsshub_instance = "https://rsshub.app",
   ---@type string[]
   curl_params = {},
   options = {
      ---@type table<string, any>
      index = {
         swapfile = false,
         undolevels = -1,
         undoreload = 0,
         conceallevel = 0,
         signcolumn = "no",
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
         listchars = "",
         spell = false,
      },
   },
   ---@type table[]
   layout = {
      -- TODO: validate
      {
         "date",
         width = 10,
         color = "FeedDate",
      },
      {
         "feed",
         width = 25,
         color = "FeedTitle",
      },
      {
         "tags",
         width = 15,
         color = "FeedTags",
      },
      {
         "title",
         width = 80,
         color = "FeedTitle",
      },
      {
         "last_updated",
         right = true,
         color = "FeedDate",
      },
      {
         "query",
         right = true,
         color = "FeedLabel",
      },
   },

   search = {
      default_query = "@6-months-ago +unread",
      backend = {
         "mini.pick",
         "telescope",
         "fzf-lua",
      },
   },

   progress = {
      backend = {
         "snacks",
         "fidget",
         "notify",
         "mini.notify",
         "native",
      },
   },

   data = {
      backend = "local",
   },

   ---@type feed.feed[]
   feeds = {},

   integrations = {
      telescope = {},
   },

   tag2icon = {
      pod = "📻",
      unread = "👀",
      read = "✅",
      star = "🌟",
      news = "📰",
      tech = "🦾",
      app = "📱",
      blog = "📝",
      email = "📧",
   },

   keys = {
      index = {
         hints = "?",
         _dot = ".",
         _undo = "u",
         entry = "<CR>",
         split = "<M-CR>",
         browser = "b",
         refresh = "r",
         search = "s",
         yank_url = "y",
         untag = "-",
         tag = "+",
         quit = "q",
      },
      entry = {
         hints = "?",
         browser = "b",
         next = "}",
         prev = "{",
         full = "f",
         search = "s",
         untag = "-",
         tag = "+",
         quit = "q",
         urlview = "r",
         yank_url = "y",
         open_url = "gx",
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

-- local function pval(name, val, validator, message)
--    return pcall(vim.validate, name, val, validator, message)
-- end
--
--
-- ---@param cfg feed.config
-- local function validate(cfg)
--    local ok, err = pval('options', cfg.options, 'table')
--    if not ok then
--       vim.notify(err)
--    end
-- end

--- Merge the user configuration with the default values.
---@param config feed.config
function M.resolve(config)
   config = config or {}
   -- validate(config)
   M.config = vim.tbl_deep_extend("keep", config, default)
end

return M
