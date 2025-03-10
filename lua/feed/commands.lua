local Config = require("feed.config")
local ut = require("feed.utils")
local db = require("feed.db")
local ui = require("feed.ui")
local feedlist = ut.feedlist

local M = {}

M.web = {
   doc = "opens server and web interface",
   impl = function(query, port)
      port = port or Config.web.port
      require("feed.server").open(query, port)
      vim.ui.open("http://0.0.0.0:" .. port)
   end,
}

M.load_opml = {
   doc = "takes filepath of your opml",
   impl = function(path)
      if path then
         ui.load_opml(path)
      else
         ui.input({ prompt = "path or url to your opml: ", completion = "file_in_path" }, ui.load_opml)
      end
   end,
}

M.export_opml = {
   doc = "exports opml to a filepath",
   impl = function(fp)
      if fp then
         ui.export_opml(fp)
      else
         ui.input({ prompt = "export your opml to: ", completion = "file_in_path" }, ui.export_opml)
      end
   end,
}

M.search = {
   doc = "search the database by time, tags or regex",
   impl = ui.search,
}

M.grep = {
   doc = "full-text search through the entry contents",
   impl = ui.grep,
}

M.refresh = {
   doc = "refresh the index buffer",
   impl = ui.refresh,
}

M.log = {
   doc = "show log",
   impl = ui.show_log,
}

M.browser = {
   doc = "open entry link in browser with vim.ui.open",
   impl = ui.show_browser,
}

M.full = {
   doc = "fetch the full text",
   impl = ui.show_full,
}

M.split = {
   doc = "show entry in split",
   impl = ui.show_split,
}

M.entry = {
   doc = "show entry in new buffer",
   impl = ui.show_entry,
}

M.index = {
   doc = "show search results in new buffer",
   impl = ui.show_index,
}

M.next = {
   doc = "show next search result",
   impl = ui.show_next,
}

M.prev = {
   doc = "show previous search result",
   impl = ui.show_prev,
}

M.hints = {
   doc = "show keymap hints",
   impl = ui.show_hints,
}

M.quit = {
   doc = "quit current view",
   impl = ui.quit,
}

M.yank_url = {
   doc = "yank link to system clipboard",
   impl = function()
      vim.fn.setreg("+", ui.get_entry().link)
   end,
}

M.undo = {
   doc = "undo",
   impl = ui.undo,
}

M.redo = {
   doc = "redo",
   impl = ui.redo,
}

M.dot = {
   doc = "dot repeat",
   impl = function()
      ui.dot()
   end,
}

M.tag = {
   doc = "tag an entry",
   impl = function(t)
      if t then
         ui.tag(t)
      else
         ui.input({ prompt = "Tag: " }, ui.tag)
      end
   end,
}

--- TODO: make tag untag visual line mode
M.untag = {
   doc = "untag an entry",
   impl = function(t)
      if t then
         ui.untag(t)
      else
         ui.input({ prompt = "Untag: " }, ui.untag)
      end
   end,
}

M.urlview = {
   doc = "list all links in entry and open selected",
   impl = ui.show_urls,
}

M.list = {
   doc = "list all feeds",
   impl = ui.show_feeds,
}

M.update = {
   doc = "update all feeds",
   impl = function()
      local n = #ut.feedlist(db.feeds, false)
      local prog = require("feed.ui.progress").new(n)
      local args = vim.v.argv
      table.remove(args, 1)
      table.remove(args, 1)
      local cmds = vim.tbl_flatten({
         "nvim",
         args,
         "--headless",
         "-c",
         'lua require"feed.fetch".update()',
      })
      vim.system(cmds, {
         text = true,
         stderr = function(_, data)
            if data and vim.trim(data) ~= "" then
               prog:update(vim.trim(data))
               vim.schedule(function()
                  if ut.in_index() then
                     ui.refresh()
                  end
               end)
            end
         end,
      })
   end,
}

M.update_feed = {
   doc = "update a feed to db",
   impl = function(url)
      if url then
         ui.update_feed(url)
      else
         ui.select(feedlist(db.feeds, true), {
            prompt = "Feed to update",
            format_item = function(item)
               local feed = db.feeds[item]
               return type(feed) == "table" and db.feeds[item].title or item
            end,
         }, ui.update_feed)
      end
   end,
   complete = function()
      return feedlist(db.feeds, true)
   end,
}

M["sync!"] = {
   doc = "remove any unlisted feed and its entries",
   impl = function()
      db:hard_sync()
   end,
}

M.sync = {
   doc = "remove any unlisted feed but not its entries",
   impl = function()
      db:soft_sync()
   end,
}

M.export = {
   doc = "use pandoc to convert entry to any format",
   impl = function(to, fp)
      local entry, id = ui.get_entry()
      require("feed.pandoc").convert({ id = id, to = to }, function(res)
         ut.save_file(vim.fs.joinpath(fp, entry.title .. "." .. to), res)
      end)
   end,
}

local entry_cmds = {
   "urlview",
   "next",
   "prev",
   "full",
   "browser",
   "export",
   "quit",
}

local index_cmds = {
   "web",
   "untag",
   "load_opml",
   "update",
   "sync!",
   "tag",
   "index",
   "update_feed",
   "list",
   "quit",
   "grep",
   "browser",
   "export_opml",
   "split",
   "log",
   "search",
   "sync",
}

local general_cmds = {
   "index",
   "update",
   "update_feed",
   "sync",
   "sync!",
   "search",
   "grep",
   "list",
   "web",
   "load_opml",
   "export_opml",
   "log",
}

function M._list_commands()
   if ut.in_entry() then
      return entry_cmds
   elseif ut.in_index() then
      return index_cmds
   else
      return general_cmds
   end
end

function M._load_command(args)
   local cmd = args[1]
   if M[cmd] then
      table.remove(args, 1)
      local item = M[cmd]
      item.impl(unpack(args))
   else
      ui.refresh(table.concat(args, " "))
   end
end

function M._menu()
   local items = M._list_commands()
   ui.select(items, {
      prompt = "Feed commands",
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

return M
