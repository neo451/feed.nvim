local config = require "feed.config"
local ut = require "feed.utils"
local db = ut.require "feed.db"
local render = require "feed.ui"
local fetch = require "feed.fetch"
local opml = require "feed.parser.opml"
local feeds = db.feeds

local read_file = ut.read_file
local save_file = ut.save_file
local wrap = ut.wrap
local input = ut.input
local select = ut.select

local M = {}

local function feedlist()
   return vim.iter(feeds)
      :filter(function(_, v)
         return type(v) == "table"
      end)
      :fold({}, function(acc, k)
         table.insert(acc, k)
         return acc
      end)
end

M.log = {
   doc = "show log",
   impl = function()
      local str = read_file(vim.fn.stdpath "data" .. "/feed.nvim.log")
      if str then
         local buf = vim.api.nvim_create_buf(false, true)
         vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(str, "\n"))
         vim.api.nvim_set_current_buf(buf)
         vim.keymap.set("n", "q", "<cmd>bd<cr>", { buffer = buf })
      end
   end,
   context = { all = true },
}

M.load_opml = {
   doc = "takes filepath of your opml",
   impl = wrap(function(fp)
      fp = fp or input { prompt = "path to your opml: ", completion = "file_in_path" }
      if not fp then
         return
      end
      fp = vim.fn.expand(fp)
      local str = read_file(fp)
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
      fp = fp or input { prompt = "export your opml to: ", completion = "file_in_path" }
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
   impl = wrap(function(query)
      local buf = vim.api.nvim_get_current_buf()
      if query then
         render.refresh { query = query }
      else
         if buf ~= render.index then
            local ok = pcall(vim.cmd.Telescope, "feed")
            if not ok then
               query = input { prompt = "Search: " }
               render.refresh { query = query }
            end
         else
            query = input { prompt = "Search: " }
            render.refresh { query = query }
         end
      end
   end),
   context = { all = true },
}

-- TODO: Native one with nui
M.grep = {
   doc = "full-text search through the entry contents (experimental)",
   impl = function()
      local ok = pcall(vim.cmd.Telescope, "feed_grep")
      if not ok then
         ut.notify("commands", { msg = "need telescope.nvim and rg to grep feeds", level = "INFO" })
      end
   end,
   context = { all = true },
}

M.refresh = {
   doc = "re-renders the index buffer",
   impl = render.refresh,
   context = { index = true },
}

M.show_in_browser = {
   doc = "open entry link in browser with vim.ui.open",
   impl = function()
      local entry = render.get_entry()
      if entry then
         local link = entry.link
         if link then
            M.untag.impl "unread"
            vim.ui.open(link)
         end
      else
         ut.notify("show_in_browser", { msg = "no link for entry you try to open", level = "INFO" })
      end
   end,
   context = { index = true, entry = true },
}

M.show_in_split = {
   doc = "show entry in split",
   impl = function()
      local Split = require "nui.split"
      local event = require("nui.utils.autocmd").event

      local split = Split {
         relative = "editor",
         position = "bottom",
         size = "50%",
      }
      local _, id = render.get_entry()
      split:mount()
      -- TODO: fix ShowEntryPost
      -- TODO: move to render.lua
      render.show_entry { buf = split.bufnr, id = id }
      vim.keymap.set("n", "q", function()
         split:unmount()
      end, { buffer = split.bufnr, noremap = true })
      split:on(event.BufLeave, function()
         split:unmount()
      end)
   end,
   context = { index = true },
}

M.show_entry = {
   doc = "show entry in new buffer",
   impl = render.show_entry,
   context = { index = true },
}

M.show_index = {
   doc = "show query results in new buffer",
   impl = render.show_index,
   context = { all = true },
}

M.quit = {
   doc = "quit current view",
   impl = render.quit,
   context = { entry = true, index = true },
}

M.show_next = {
   doc = "show next query result",
   impl = function()
      if render.current_index == #render.on_display then
         return
      end
      render.show_entry { row_idx = render.current_index + 1 }
   end,
   context = { entry = true },
}

M.show_prev = {
   doc = "show previous query result",
   impl = function()
      if render.current_index == 1 then
         return
      end
      render.show_entry { row_idx = render.current_index - 1 }
   end,
   context = { entry = true },
}

M.link_to_clipboard = {
   doc = "yank link to system clipboard",
   impl = function()
      vim.fn.setreg("+", render.get_entry().link)
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
         _, id, _ = render.get_entry()
      end
      tag = tag or input { prompt = "Tag: " }
      save_hist = vim.F.if_nil(save_hist, true)
      if not tag or not id then
         return
      end
      db:tag(id, tag)
      local buf = vim.api.nvim_get_current_buf()
      if buf == render.index then
         render.refresh()
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
         _, id, _ = render.get_entry()
      end
      save_hist = vim.F.if_nil(save_hist, true)
      tag = tag or input { prompt = "Untag: " }
      if not tag or not id then
         return
      end
      db:untag(id, tag)
      local buf = vim.api.nvim_get_current_buf()
      if buf == render.index then
         render.refresh()
      end
      dot = function()
         M.untag.impl(tag)
      end
      if save_hist then
         table.insert(tag_hist, { type = "untag", tag = tag, id = id })
      end
   end),
   context = { index = true, entry = true },
   -- TODO: completion for in-db tags , tags.lua
}

M.open_url = {
   doc = "open url under cursor",
   impl = wrap(function()
      vim.cmd.normal "yi["
      local text = vim.fn.getreg "0"
      local item = vim.iter(render.state.urls):find(function(v)
         return v[1] == text
      end)
      if item then
         if not ut.looks_like_url(item[2]) then
            ut.notify("urlview", { msg = "reletive link resolotion is to be implemented", level = "ERROR" })
         else
            vim.ui.open(item[2])
         end
      end
   end),
   context = { entry = true },
}

M.urlview = {
   doc = "list all links in entry and open selected",
   impl = wrap(function()
      local items = render.state.urls
      local item = select(items, {
         prompt = "urlview",
         format_item = function(item)
            return item[1]
         end,
      })
      if item then
         if not ut.looks_like_url(item[2]) then
            ut.notify("urlview", { msg = "reletive link resolotion is to be implemented", level = "ERROR" })
         else
            vim.ui.open(item[2])
         end
      end
   end),
   context = { entry = true },
}

M.list = {
   doc = "list all feeds",
   impl = function()
      for _, url in ipairs(feedlist()) do
         print(feeds[url] and feeds[url].title or url, url, feeds[url] and feeds[url].tags and vim.inspect(feeds[url].tags))
      end
   end,
   context = { all = true },
}

M.update = {
   doc = "update all feeds",
   impl = function()
      fetch.update_feeds(feedlist(), 10)
   end,
   context = { all = true },
}

M.update_feed = {
   doc = "update a feed to db",
   impl = wrap(function(url)
      url = url
         or select(feedlist(), {
            prompt = "Feed to update",
            format_item = function(item)
               return feeds[item].title or item
            end,
         })
      if not url then
         return
      end
      fetch.update_feed(url, 1)
   end),

   complete = function()
      return feedlist()
   end,
   context = { all = true },
}

-- TODO:
M.prune_feed = {
   doc = "remove a feed from feedlist, and all its entries",
   impl = wrap(function(url)
      url = url
         or select(feedlist(), {
            prompt = "Feed to remove",
            format_item = function(item)
               return feeds[item].title or item
            end,
         })
      if not url then
         return
      end
      local title = feeds[url].title
      feeds[url] = nil
      db:save_feeds()
      for id, entry in db:iter() do
         if entry.feed == title then
            db:rm(id)
         end
      end
   end),
   context = { all = true },
}

function M._list_commands()
   local buf = vim.api.nvim_get_current_buf()
   local choices = vim.iter(vim.tbl_keys(M)):filter(function(v)
      return v:sub(0, 1) ~= "_"
   end)
   if render.entry == buf then
      choices = choices:filter(function(v)
         return M[v].context.entry or M[v].context.all
      end)
   elseif render.index == buf then
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
      render.refresh { query = table.concat(args, " ") }
   end
end

function M._menu()
   local items = M._list_commands()
   vim.ui.select(items, {
      prompt = "Feed commands",
      format_item = function(item)
         return item .. ": " .. M[item].doc
      end,
   }, function(choice)
      if choice then
         local item = M[choice]
         item.impl()
      end
   end)
end

function M._sync_feedlist()
   for _, v in ipairs(config.feeds) do
      local url = type(v) == "table" and v[1] or v
      local name = type(v) == "table" and v.name or nil
      local tags = type(v) == "table" and v.tags or nil
      if not feeds[url] then
         feeds[url] = {
            title = name,
            tags = tags,
         }
      end
   end
   db:save_feeds()
end

local augroup = vim.api.nvim_create_augroup("Feed", {})

function M._register_autocmds()
   vim.api.nvim_create_autocmd("User", {
      pattern = "ShowEntryPost",
      group = augroup,
      callback = function(_)
         vim.cmd "set cmdheight=0"
         config.on_attach { index = render.index, entry = render.entry }
         if config.colorscheme then
            vim.cmd.colorscheme(config.colorscheme)
         end
         ut.highlight_entry(render.entry)

         if config.enable_default_keybindings then
            local function eset(lhs, rhs)
               vim.keymap.set("n", lhs, rhs.impl, { buffer = render.entry, noremap = true })
            end
            eset("b", M.show_in_browser)
            eset("s", M.search)
            eset("+", M.tag)
            eset("-", M.untag)
            eset("q", M.quit)
            eset("r", M.urlview)
            eset("}", M.show_next)
            eset("{", M.show_prev)
            eset("gx", M.open_url)
         end
         for key, value in pairs(config.options.entry) do
            pcall(vim.api.nvim_set_option_value, key, value, { buf = render.entry })
            pcall(vim.api.nvim_set_option_value, key, value, { win = vim.api.nvim_get_current_win() })
         end

         local conform_ok, conform = pcall(require, "conform")

         if conform_ok then
            vim.api.nvim_set_option_value("modifiable", true, { buf = render.entry })
            pcall(conform.format, { formatter = { "injected" }, filetype = "markdown", bufnr = render.entry })
            vim.api.nvim_set_option_value("modifiable", false, { buf = render.entry })
         else
            vim.lsp.buf.format { bufnr = render.entry }
         end
      end,
   })

   vim.api.nvim_create_autocmd("User", {
      pattern = "ShowIndexPost",
      group = augroup,
      callback = function(_)
         vim.cmd "set cmdheight=0"
         config.on_attach { index = render.index, entry = render.entry }
         if config.colorscheme then
            vim.cmd.colorscheme(config.colorscheme)
         end
         if config.enable_default_keybindings then
            local function iset(lhs, rhs)
               vim.keymap.set("n", lhs, rhs.impl, { buffer = render.index, noremap = true })
            end
            iset(".", M._dot)
            iset("u", M._undo)
            iset("<CR>", M.show_entry)
            iset("<M-CR>", M.show_in_split)
            iset("r", M.refresh)
            iset("b", M.show_in_browser)
            iset("s", M.search)
            iset("y", M.link_to_clipboard)
            iset("+", M.tag)
            iset("-", M.untag)
            iset("q", M.quit)
         end
         for key, value in pairs(config.options.index) do
            pcall(vim.api.nvim_set_option_value, key, value, { buf = render.index })
            pcall(vim.api.nvim_set_option_value, key, value, { win = vim.api.nvim_get_current_win() })
         end
      end,
   })
end

return M
