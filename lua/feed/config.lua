---@class feed.searchOpts
---@field backend "telescope" | "mini.pick" | "fzf-lua"
---@field sort_order? "ascending" | "descending"
---@field default_query? string

---@class feed.progressOpts
---@field backend "mini.notify" | "snacks" | "fidget" | "native"

---@class feed.rsshubOpts
---@field instance? string
---@field export? string move all options here as a enum??

---@class feed.section
---@field width? integer | "#"
---@field color? string
---@field format? fun(id: string, db: feed.db): string

---@class feed.ttrssOpts
---@field url? string
---@field user? string
---@field password? string

---@class feed.localOpts
---@field dir? string

---@class feed.protocolOpts
---@field backend "local" | "ttrss"
---@field ttrss? feed.ttrssOpts
---@field local? feed.ttrssOpts

---@class feed.dateOpts
---@field format? { long: string, short: string }

---@alias feed.layout table<string, feed.section | table<number, string>>

---@class feed.config
---@field feeds? string | { name: string, tags: table }
---@field date? feed.dateOpts
---@field curl_params? string[]
---@field rsshub? feed.rsshubOpts
---@field ui? feed.layout
---@field entry? feed.layout
---@field winbar? feed.layout
---@field picker? feed.layout
---@field progress? feed.progressOpts
---@field search? feed.searchOpts
---@field protocol? feed.protocolOpts
---@field options? { entry: { wo: vim.wo|{}, bo: vim.bo|{} }, index: { wo: vim.wo|{}, bo: vim.bo|{} } }

local formats = {}

formats.date_long = function(id, db)
   return os.date(require("feed.config").date.format.long, db[id].time)
end

formats.date_short = function(id, db)
   return os.date(require("feed.config").date.format.short, db[id].time)
end

formats.link = function(id, db)
   return db[id].link and db[id].link:sub(1, 90) or ""
end

formats.feed = function(id, db)
   local feed_url = db[id].feed
   return db.feeds[feed_url] and db.feeds[feed_url].title or feed_url
end

formats.author = function(id, db)
   local entry = db[id]
   return entry.author and entry.author or formats.feed(id, db)
end

formats.tags = function(id, db)
   local tags = db:get_tags(id)
   return ("[%s]"):format(table.concat(tags, ", "))
end

formats.title = function(id, db)
   return db[id].title
end

---@class feed._config
local default = {
   ---@type { long: string, short: string }
   date = {
      format = {
         short = "%Y-%m-%d",
         long = "%c",
      },
   },
   ---@type { instance: string, export: string }
   rsshub = {
      instance = "https://rsshub.app",
      export = "https://rsshub.app",
   },
   ---@type string[]
   curl_params = {},
   ---@type table[]
   ui = {
      order = { "date", "feed", "tags", "title" },
      date = {
         color = "FeedDate",
         format = formats.date_short,
      },
      feed = {
         width = 25,
         color = "FeedTitle",
         format = formats.feed,
      },
      tags = {
         width = 20,
         color = "FeedTags",
         format = formats.tags,
      },
      title = {
         color = "FeedTitle",
         format = formats.title,
      },
      query = {
         color = "FeedLabel",
      },
      last_updated = {
         color = "FeedDate",
      },
   },

   entry = {
      order = { "title", "author", "feed", "link", "date", "tags" },
      link = {
         format = formats.link,
      },
      date = {
         format = formats.date_long,
      },
      author = {
         format = formats.author,
      },
      feed = {
         format = formats.feed,
      },
      tags = {
         format = formats.tags,
      },
      title = {
         format = formats.title,
      },
   },

   winbar = {
      order = { "date", "feed", "tags", "title", "%=%<", "query", "last_updated" },
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
         width = "#",
         color = "FeedTitle",
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
         format = formats.feed,
      },
      tags = {
         width = 15,
         color = "FeedTags",
         format = formats.tags,
      },
      title = {
         color = "FeedTitle",
         format = formats.title,
      },
   },

   -- TODO: layout for winbar

   search = {
      default_query = "@2-weeks-ago +unread ",
      sort_order = "descending",
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
      ["local"] = {
         dir = vim.fn.stdpath("data") .. "/feed",
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
         yank_url = "Y",
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
         yank_url = "Y",
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
            foldmethod = "expr",
            foldlevel = 99,
            foldexpr = "v:lua.vim.treesitter.foldexpr()",
            foldtext = "",
            fillchars = "foldopen:,foldclose:,fold: ,foldsep: ",
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

M._default = vim.deepcopy(default)

return M
