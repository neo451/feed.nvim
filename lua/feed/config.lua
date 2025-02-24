---@class feed.config
---@field feeds? string | { name: string, tags: table }
---@field db_dir? string
---@field date_format? string
---@field curl_params? string[]
---@field rsshub? { instance: string, export: string } move all options here as a enum??
---@field layout? table
---@field progress? { backend: "mini.notify" | "snacks" | "fidget" | "native" }
---@field search? { backend: "telescope" | "mini.pick" | "fzf-lua", default_query: string }
---@field data? { backend: "local" | "ttrss" }
---@field options? { entry: { wo: vim.wo|{}, bo: vim.bo|{} }, index: { wo: vim.wo|{}, bo: vim.bo|{} } }

---@class feed._config
local default = {
   ---@type string
   db_dir = vim.fn.stdpath("data") .. "/feed",
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
         enabled = false,
      },
      order = { "date", "feed", "tags", "title" },
      winbar_right = { "query", "last_updated" },
      date = {
         width = 10,
         color = "FeedDate",
      },
      feed = {
         width = 25,
         color = "FeedTitle",
      },
      tags = {
         width = 20,
         color = "FeedTags",
      },
      title = {
         color = "FeedTitle",
      },
      progress = {
         color = "FeedDate",
      },
      query = {
         color = "FeedLabel",
      },
      last_updated = {
         color = "FeedDate",
      },
   },

   picker = {
      order = { "feed", "tags", "title" },
      feed = {
         width = 15,
         color = "FeedTitle",
      },
      tags = {
         width = 15,
         color = "FeedTags",
      },
      title = {
         color = "FeedTitle",
      },
   },

   -- TODO: layout for winbar

   search = {
      default_query = "@2-weeks-ago +unread ",
      backend = {
         "mini.pick",
         "telescope",
         "fzf-lua",
      },
   },

   progress = {
      backend = {
         "fidget",
         "mini.notify",
         "snacks",
         "native",
      },
   },

   protocol = {
      backend = "local",
      ttrss = {
         url = nil,
         user = nil,
         password = nil,
      },
   },

   ---@type feed.feed[]
   feeds = {},

   keys = {
      index = {
         hints = "?",
         dot = ".",
         undo = "u",
         redo = "<C-r>",
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
         urlview = "r",
         yank_url = "y",
         quit = "q",
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
            concealcursor = "nvc",
         },
         bo = {
            filetype = "markdown",
            swapfile = false,
            undolevels = -1,
            modifiable = false,
         },
      },
   },
   web = {
      port = 9876,
   },
   zen = {
      enabled = true,
      width = 90,
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
