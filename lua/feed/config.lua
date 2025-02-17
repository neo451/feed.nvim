---@class feed.config
---@field feeds? string | { name: string, tags: table }
---@field colorscheme? string
---@field db_dir? string
---@field date_format? string
---@field curl_params? string[]
---@field rsshub? { instance: string, export: string } move all options here as a enum??
---@field layout? table
---@field progress? { backend: "mini.notify" | "snacks" | "nvim-notify" | "fidget" | "native" }
---@field search? { backend: "telescope" | "mini.pick" | "fzf-lua", default_query: string }
---@field data? { backend: "local" | "ttrss" }
---@field options? { entry: { wo: vim.wo|{}, bo: vim.bo|{} }, index: { wo: vim.wo|{}, bo: vim.bo|{} } }

---@class feed._config
local default = {
   ---@type string
   db_dir = vim.fn.stdpath("data") .. "/feed",
   ---@type string
   colorscheme = nil,
   ---@type { long: string, short: string }
   date_format = {
      short = "%Y-%m-%d",
      long = "%c",
   },
   ---@type { instance: string, export: string }
   rsshub = {
      instance = "https://rsshub.app",
      export = "https://rsshub.app",
   },
   ---@type string[]
   curl_params = {},
   ---@type table[]
   layout = {
      padding = {
         enabled = true,
      },
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
         color = "FeedTitle",
      },
      {
         "progress",
         right = true,
         color = "FeedDate",
      },
      {
         "query",
         right = true,
         color = "FeedLabel",
      },
      {
         "last_updated",
         right = true,
         color = "FeedDate",
      },
   },

   search = {
      default_query = "@6-months-ago +unread ",
      -- show_last = false,
      backend = {
         "mini.pick",
         "telescope",
         "fzf-lua",
      },
   },

   progress = {
      backend = {
         "fidget",
         "nvim-notify",
         "mini.notify",
         "snacks",
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

   icons = {
      enabled = false,
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
         update = "R",
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
   options = {
      ---@type { wo: table, bo: table }
      index = {
         wo = {
            signcolumn = "no",
            wrap = false,
            number = false,
            relativenumber = false,
            list = false,
            statuscolumn = " ",
            spell = false,
            conceallevel = 0,
         },
         bo = {
            filetype = "feed",
            swapfile = false,
            undolevels = -1,
            modifiable = false,
         },
      },

      ---@type { wo: table, bo: table }
      entry = {
         wo = {
            signcolumn = "no",
            wrap = true,
            number = false,
            relativenumber = false,
            list = false,
            statuscolumn = " ",
            spell = false,
            conceallevel = 3,
            concealcursor = "n",
         },
         bo = {
            filetype = "markdown",
            swapfile = false,
            undolevels = -1,
            modifiable = false,
         },
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

local function pval(name, val, validator, message)
   return pcall(vim.validate, name, val, validator, message)
end

---@param cfg feed.config
local function validate(cfg)
   local path = {
      db_dir = "string",
      colorscheme = "string",
      date_format = "string",
      rsshub = "table",
      curl_params = "table",
      options = "table",
      layout = "table",
      search = "table",
      progress = "table",
      data = "table",
      feeds = "table",
      keys = "table",
      icons = "table",
   }
   for k, v in pairs(path) do
      local ok, err = pval(k, cfg[k], v)
      if not ok then
         vim.notify("failed to validate feed.nvim config at config." .. err)
      end
   end
end

--- Merge the user configuration with the default values.
---@param config feed.config
function M.resolve(config)
   config = config or {}
   M.config = vim.tbl_deep_extend("keep", config, default)
   -- validate(M.config)
end

return M
