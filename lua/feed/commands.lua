local Config = require("feed.config")
local ut = require("feed.utils")
local db = require("feed.db")
local ui = require("feed.ui")
local opml = require("feed.parser.opml")
local feeds = db.feeds
local nui = require("feed.ui.nui")
local curl = require("feed.curl")
local fetch = require("feed.fetch")
local log = require("feed.lib.log")

local read_file = ut.read_file
local save_file = ut.save_file
local wrap = ut.wrap
local input = ut.input
local feedlist = ut.feedlist

local M = {}

M.load_opml = {
   doc = "takes filepath of your opml",
   impl = wrap(function(fp)
      fp = fp or input({ prompt = "path or url to your opml: ", completion = "file_in_path" })
      if not fp then
         return
      end
      local str
      if ut.looks_like_url(fp) then
         str = curl.fetch_co(fp, {}).stdout
      else
         fp = vim.fn.expand(fp)
         str = read_file(fp)
      end
      if str then
         local outlines = opml.import(str)
         if outlines then
            for k, v in pairs(outlines) do
               feeds[k] = v
            end
         else
            ut.notify("opml", { msg = "failed to parse your opml file", level = "ERROR" })
         end
         db:save_feeds()
      else
         ut.notify("opml", { msg = "failed to open your opml file", level = "ERROR" })
      end
   end),
   context = { all = true },
}

M.export_opml = {
   doc = "exports opml to a filepath",
   impl = wrap(function(fp)
      fp = fp or input({ prompt = "export your opml to: ", completion = "file_in_path" })
      fp = vim.fn.expand(fp)
      if not fp then
         return
      end
      local str = opml.export(feeds)
      local ok = save_file(fp, str)
      if not ok then
         ut.notify("commands", { msg = "failed to open your expert path", level = "INFO" })
      end
   end),
   context = { all = true },
}

M.search = {
   doc = "query the database by time, tags or regex",
   impl = ui.search,
   context = { all = true },
}

-- TODO: Native one with nui
M.grep = {
   doc = "full-text search through the entry contents (experimental)",
   impl = function()
      local ok = pcall(require("feed.ui.telescope").feed_grep)
      if not ok then
         ut.notify("commands", { msg = "need telescope.nvim and rg to grep feeds", level = "INFO" })
      end
   end,
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
   doc = "show query results in new buffer",
   impl = ui.show_index,
   context = { all = true },
}

M.next = {
   doc = "show next query result",
   impl = ui.show_next,
   context = { entry = true },
}

M.prev = {
   doc = "show previous query result",
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

local dot = function() end
local tag_hist = {}

M._undo = {
   impl = function()
      local act = table.remove(tag_hist, #tag_hist)
      if not act then
         return
      end
      if act.type == "tag" then
         M.untag.impl(act.tag, act.id, false)
      elseif act.type == "untag" then
         M.tag.impl(act.tag, act.id, false)
      end
   end,
   context = { index = true },
}

M._dot = {
   impl = function()
      dot()
   end,
   context = { index = true },
}

M.tag = {
   doc = "tag an entry",
   impl = wrap(function(tag, id, save_hist)
      if not id then
         _, id = ui.get_entry()
      end
      tag = tag or input({ prompt = "Tag: " })
      save_hist = vim.F.if_nil(save_hist, true)
      if not tag or not id then
         return
      end
      db:tag(id, tag)
      if ut.in_index() then
         ui.refresh()
      end
      dot = function()
         M.tag.impl(tag)
      end
      if save_hist then
         table.insert(tag_hist, { type = "tag", tag = tag, id = id })
      end
   end),
   context = { index = true, entry = true },
}

--- TODO: make tag untag visual line mode
M.untag = {
   doc = "untag an entry",
   impl = wrap(function(tag, id, save_hist)
      if not id then
         _, id, _ = ui.get_entry()
      end
      save_hist = vim.F.if_nil(save_hist, true)
      tag = tag or input({ prompt = "Untag: " })
      if not tag or not id then
         return
      end
      db:untag(id, tag)
      if ut.in_index() then
         ui.refresh()
      end
      dot = function()
         M.untag.impl(tag)
      end
      if save_hist then
         table.insert(tag_hist, { type = "untag", tag = tag, id = id })
      end
   end),
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

      local prog = Progress.new(#ut.feedlist(feeds))
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
         fetch.update_feed(url, { force = true }, function(ok)
            ut.notify("fetch", { msg = ut.url2name(url, feeds) .. (ok and " success" or "failed"), level = "INFO" })
         end)
      else
         nui.select(feedlist(feeds), {
            prompt = "Feed>",
            format_item = function(item)
               return feeds[item].title or item
            end,
         }, function(choice)
            if not choice then
               return
            end
            fetch.update_feed(choice, { force = true }, function(ok)
               ut.notify(
                  "fetch",
                  { msg = ut.url2name(choice, feeds) .. (ok and " success" or "failed"), level = "INFO" }
               )
            end)
         end)
      end
   end,

   complete = function()
      return feedlist(feeds)
   end,
   context = { all = true },
}

M.term = {
   doc = "",
   impl = function()
      local res = db:filter("#5")
      local Format = require("feed.ui.format")
      for _, id in ipairs(res) do
         print(Format.entry(db[id], {
            { "feed", width = 10 },
            { "title" },
         }))
      end
      os.exit()
   end,
   context = {},
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
      prompt = "Feed> ",
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
      if not feeds[url] then
         feeds[url] = {}
      end
      feeds[url].title = title or feeds[url].title
      feeds[url].tags = tags or feeds[url].tags
   end
   db:save_feeds()
end

return M
