local Config = require("feed.config")
local ut = require("feed.utils")
local db = require("feed.db")
local ui = require("feed.ui")
local feeds = db.feeds
local nui = require("feed.ui.nui")
local log = require("feed.lib.log")

local feedlist = ut.feedlist

local M = {}

M.load_opml = {
   doc = "takes filepath of your opml",
   impl = function(path)
      if path then
         ui.load_opml(path)
      else
         vim.ui.input({ prompt = "path or url to your opml: ", completion = "file_in_path" }, ui.load_opml)
      end
   end,
   context = { all = true },
}

M.export_opml = {
   doc = "exports opml to a filepath",
   impl = function(fp)
      if fp then
         ui.export_opml(fp)
      else
         vim.ui.input({ prompt = "export your opml to: ", completion = "file_in_path" }, ui.export_opml)
      end
   end,
   context = { all = true },
}

M.search = {
   doc = "search the database by time, tags or regex",
   impl = ui.search,
   context = { all = true },
}


M.grep = {
   doc = "full-text search through the entry contents",
   impl = ui.grep,
   context = { all = true },
}

M.refresh = {
   doc = "re-renders the index buffer",
   impl = ui.refresh,
   context = { index = true },
}

M.log = {
   doc = "show log",
   impl = ui.show_log,
   context = { all = true },
}

M.browser = {
   doc = "open entry link in browser with vim.ui.open",
   impl = ui.show_browser,
   context = { index = true, entry = true },
}

M.full = {
   doc = "fetch the full text",
   impl = ui.show_full,
   context = { entry = true },
}

M.split = {
   doc = "show entry in split",
   impl = ui.show_split,
   context = { index = true },
}

M.entry = {
   doc = "show entry in new buffer",
   impl = ui.show_entry,
   context = { index = true },
}

M.index = {
   doc = "show search results in new buffer",
   impl = ui.show_index,
   context = { all = true },
}

M.next = {
   doc = "show next search result",
   impl = ui.show_next,
   context = { entry = true },
}

M.prev = {
   doc = "show previous search result",
   impl = ui.show_prev,
   context = { entry = true },
}

M.hints = {
   doc = "show keymap hints",
   impl = ui.show_hints,
   context = { entry = true, index = true },
}

M.quit = {
   doc = "quit current view",
   impl = ui.quit,
   context = { entry = true, index = true },
}

M.open_url = {
   doc = "open url under cursor",
   impl = ui.open_url,
   context = { entry = true },
}

M.yank_url = {
   doc = "yank link to system clipboard",
   impl = function()
      vim.fn.setreg("+", ui.get_entry().link)
   end,
   context = { index = true, entry = true },
}

M._undo = {
   impl = ui.undo,
   context = { index = true },
}

M._dot = {
   impl = function()
      ui.dot()
   end,
   context = { index = true },
}


M.tag = {
   doc = "tag an entry",
   impl = function(t)
      if t then
         ui.tag(t)
      else
         vim.ui.input({ prompt = "Tag: " }, ui.tag)
      end
   end,
   context = { index = true, entry = true },
}


--- TODO: make tag untag visual line mode
M.untag = {
   doc = "untag an entry",
   impl = function(t)
      if t then
         ui.untag(t)
      else
         vim.ui.input({ prompt = "Untag: " }, ui.untag)
      end
   end,
   context = { index = true, entry = true },
}

M.urlview = {
   doc = "list all links in entry and open selected",
   impl = ui.show_urls,
   context = { entry = true },
}

M.list = {
   doc = "list all feeds",
   impl = ui.show_feeds,
   context = { all = true },
}

M.update = {
   doc = "update all feeds",
   impl = function()
      local Progress = require("feed.ui.progress")
      local prog = Progress.new(#ut.feedlist(feeds, false))
      vim.system({ "nvim", "--headless", "-c", 'lua require"feed.fetch".update_all()' }, {
         text = true,
         stdout = function(err, data)
            if data then
               prog:update(vim.trim(data))
            end
         end,
         stderr = function(err, data)
            if data then
               log.warn(data)
            end
         end,
      })
   end,
   context = { all = true },
}

M.update_feed = {
   doc = "update a feed to db",
   impl = function(url)
      if url then
         ui.update_feed(url)
      else
         nui.select(feedlist(feeds, true), {
            prompt = "Feed to update>",
            format_item = function(item)
               local feed = feeds[item]
               return type(feed) == "table" and feeds[item].title or item
            end,
         }, ui.update_feed)
      end
   end,

   complete = function()
      return feedlist(feeds, true)
   end,
   context = { all = true },
}

M.prune_feed = {
   doc = "remove a feed and its entries",
   -- TODO: remove db links/refs
   impl = function(url)
      if url then
         ui.prune_feed(url)
      else
         nui.select(feedlist(feeds, true), {
            prompt = "Feed to prune>",
            format_item = function(item)
               local feed = feeds[item]
               return type(feed) == "table" and feeds[item].title or item
            end,
         }, ui.prune_feed)
      end
   end,
   complete = function()
      return feedlist(feeds, true)
   end,
   context = { all = true }
}

function M._list_commands()
   local choices = vim.iter(vim.tbl_keys(M)):filter(function(v)
      return v:sub(0, 1) ~= "_"
   end)
   if ut.in_entry() then
      choices = choices:filter(function(v)
         return M[v].context.entry or M[v].context.all
      end)
   elseif ut.in_index() then
      choices = choices:filter(function(v)
         return M[v].context.index or M[v].context.all
      end)
   else
      choices = choices:filter(function(v)
         return M[v].context.all
      end)
   end
   return choices:totable()
end

function M._load_command(args)
   local cmd = args[1]
   if M[cmd] then
      table.remove(args, 1)
      local item = M[cmd]
      item.impl(unpack(args))
   else
      ui.refresh({ query = table.concat(args, " ") })
   end
end

function M._menu()
   local items = M._list_commands()
   nui.select(items, {
      prompt = "Feed commands> ",
      format_item = function(item)
         return item .. ": " .. M[item].doc
      end,
   }, function(choice)
      if not choice then
         return
      end
      local item = M[choice]
      item.impl()
   end)
end

function M._sync_feedlist()
   for _, v in ipairs(Config.feeds) do
      local url = type(v) == "table" and v[1] or v
      local title = type(v) == "table" and v.name or nil
      local tags = type(v) == "table" and v.tags or nil
      if feeds[url] == nil then
         feeds[url] = {}
      elseif type(feeds[url]) == "table" then
         feeds[url].title = title or feeds[url].title
         feeds[url].tags = tags or feeds[url].tags
      end
   end
end

return M
