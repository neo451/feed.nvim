---@class feed.searchOpts
---@field backend "telescope" | "mini.pick" | "fzf-lua" | "snacks.pick"
---@field sort_order? "ascending" | "descending"
---@field ignorecase? boolean
---@field default_query? string

---@class feed.progressOpts
---@field backend? "bar" | "mini.notify" | "snacks" | "fidget"
---@field ok? string icon/string for success
---@field err? string icon/string for error

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
---@field locale? string
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
---@field keys? { index: feed.key[], entry: feed.key[] }

---@alias feed.key table<string | number, string | function>

local formats = {}

---@type feed.config
local default

formats.date_long = function(id, db)
   os.setlocale(default.date.locale, "time")
   local ret = os.date(require("feed.config").date.format.long, db[id].time)
   os.setlocale("C", "time")
   return ret
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

default = {
   web = {
      port = 9876,
      open_browser = true,
   },

   zen = {
      enabled = true,
      width = 90,
   },

   date = {
      locale = "C",
      format = {
         short = "%Y-%m-%d",
         long = "%c",
      },
   },

   rsshub = {
      instance = "https://rsshub.app",
      export = "https://rsshub.app",
   },

   curl_params = {},

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
      order = { "date", "feed", "tags", "title", "%=%<", "progress", "query", "last_updated" },
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
      progress = {
         color = "FeedProgress",
         format = function()
            return vim.g.feed_progress or ""
         end,
      },
      query = {
         color = "FeedLabel",
         format = function()
            return vim.trim(require("feed.ui").state.query)
         end,
      },
      last_updated = {
         color = "FeedDate",
         format = function()
            return require("feed.db"):last_updated()
         end,
      },
   },

   progress = {
      backend = nil,
      ok = "ok",
      err = "err",
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

   search = {
      default_query = "@2-weeks-ago +unread ",
      sort_order = "descending",
      ignorecase = true,
      backend = {
         "snacks.picker",
         "mini.pick",
         "telescope",
         "fzf-lua",
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

   feeds = {},

   keys = {
      index = {
         { "q", "<cmd>Feed quit<cr>" },
         { "?", "<cmd>Feed hints<cr>" },
         { ".", "<cmd>Feed dot<cr>" },
         { "u", "<cmd>Feed undo<cr>" },
         { "<C-r>", "<cmd>Feed redo<cr>" },
         { "<M-CR>", "<cmd>Feed split<cr>" },
         { "b", "<cmd>Feed browser<cr>" },
         { "r", "<cmd>Feed refresh<cr>" },
         { "R", "<cmd>Feed update<cr>" },
         { "/", "<cmd>Feed search<cr>" },
         { "Y", "<cmd>Feed yank_url<cr>" },
         { "-", "<cmd>Feed untag<cr>" },
         { "+", "<cmd>Feed tag<cr>" },
         { "<cr>", "<cmd>Feed entry<cr>" },
      },
      entry = {
         { "q", "<cmd>Feed quit<cr>" },
         { "?", "<cmd>Feed hints<cr>" },
         { "Y", "<cmd>Feed yank_url<cr>" },
         { "b", "<cmd>Feed browser<cr>" },
         { "}", "<cmd>Feed next<cr>" },
         { "{", "<cmd>Feed prev<cr>" },
         { "/", "<cmd>Feed search<cr>" },
         { "-", "<cmd>Feed untag<cr>" },
         { "+", "<cmd>Feed tag<cr>" },
         { "f", "<cmd>Feed full<cr>" },
         { "r", "<cmd>Feed urlview<cr>" },
      },
   },

   options = {
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

   url_formats = {
      {
         pattern = "^r/%S+",
         import = function(url)
            return "https://www.reddit.com/" .. url .. ".rss"
         end,
      },
      {
         pattern = "^g?i?t?h?u?b?:?/?/?[%a%d][%a%d%-]*/[%a%d][%w%-_.]*",
         import = function(url)
            local user, repo
            if url:find("github.com") and not url:find("news.txt") then
               user, repo = url:match("github.com/([^/]+)/([^/]+)")
            elseif url:find("^github:/") then
               user, repo = url:match("github://([^/]+)/([^/]+)")
            else
               user, repo = url:match("^([^/]+)/([^/]+)")
            end
            if not user or not repo then
               return url
            end
            local feedtype = "commits"
            if url:find("releases") then
               feedtype = "releases"
            end
            return ("https://github.com/%s/%s/%s.atom"):format(user, repo, feedtype)
         end,
      },
      {
         pattern = "^rsshub://",
         import = function(url)
            local instance = require("feed.config").rsshub.instance
            return url:gsub("rsshub:/", instance) .. "?format=json?mode=fulltext"
         end,
         export = function(url)
            local instance = require("feed.config").rsshub.export
            return url:gsub("rsshub:/", instance)
         end,
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
   config.keys = config.keys or {}
   local index_keys, entry_keys = config.keys.index, config.keys.entry

   config.keys.index, config.keys.entry = nil, nil

   M.config = vim.tbl_deep_extend("keep", config, default)

   vim.list_extend(M.config.keys.index, index_keys or {})
   vim.list_extend(M.config.keys.entry, entry_keys or {})
   -- validate(M.config)
end

M._default = vim.deepcopy(default)

return M
