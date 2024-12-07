local Config = require "feed.config"
local ut = require "feed.utils"
local db = ut.require "feed.db"
local ui = require "feed.ui"
local opml = require "feed.parser.opml"
local feeds = db.feeds
local nui = require "feed.ui.nui"
local curl = require "feed.curl"

local read_file = ut.read_file
local save_file = ut.save_file
local wrap = ut.wrap
local input = ut.input
local feedlist = ut.feedlist

local M = {}

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

--- TODO: allow url
M.load_opml = {
   doc = "takes filepath of your opml",
   impl = wrap(function(fp)
      fp = fp or input { prompt = "path or url to your opml: ", completion = "file_in_path" }
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
   impl = function(query)
      local backend = ut.choose_backend(Config.search.backend)
      if query then
         ui.refresh { query = query }
      elseif ut.in_index() or not backend then
         vim.ui.input({ prompt = "Feed query: " }, function(val)
            if not val then
               return
            end
            ui.refresh { query = val }
         end)
      else
         local engine = require("feed.ui." .. backend)
         pcall(engine.feed_search)
      end
   end,
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

M.show_browser = {
   doc = "open entry link in browser with vim.ui.open",
   impl = ui.show_browser,
   context = { index = true, entry = true },
}

M.show_full = {
   doc = "fetch the full text",
   impl = ui.show_full,
   context = { entry = true },
}

M.show_split = {
   doc = "show entry in split",
   impl = ui.show_split,
   context = { index = true },
}

M.show_entry = {
   doc = "show entry in new buffer",
   impl = ui.show_entry,
   context = { index = true },
}

M.show_index = {
   doc = "show query results in new buffer",
   impl = ui.show_index,
   context = { all = true },
}

M.show_next = {
   doc = "show next query result",
   impl = ui.show_next,
   context = { entry = true },
}

M.show_prev = {
   doc = "show previous query result",
   impl = ui.show_prev,
   context = { entry = true },
}

M.show_hints = {
   doc = "show keymap hints",
   impl = ui.show_hints,
   context = { entry = true, index = true },
}

M.quit = {
   doc = "quit current view",
   impl = ui.quit,
   context = { entry = true, index = true },
}

M.link_to_clipboard = {
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
      tag = tag or input { prompt = "Tag: " }
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
      tag = tag or input { prompt = "Untag: " }
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

M.open_url = {
   doc = "open url under cursor",
   impl = ui.open_url,
   context = { entry = true },
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
      local Progress = require "feed.ui.progress"

      local prog = Progress.new(#ut.feedlist(feeds))
      vim.system({ "nvim", "--headless", "-c", 'lua require"feed.fetch".update_all()' }, {
         text = true,
         stdout = function(err, data)
            if data then
               prog:update(vim.trim(data))
            end
         end,
         -- TODO: handle err better
         stderr = function(err, data)
            if data then
               vim.notify(err, data)
            end
         end,
      })
   end,
   context = { all = true },
}

M.update_feed = {
   doc = "update a feed to db",
   impl = function(url)
      -- if url then
      --    return fetch.update_feed({ url }, 1, { force = true })
      -- else
      --    -- TODO: use nui.select
      --    vim.ui.select(feedlist(feeds), {
      --       prompt = "Feed to update",
      --       format_item = function(item)
      --          return feeds[item].title or item
      --       end,
      --    }, function(choice)
      --       if not choice then
      --          return
      --       end
      --       return fetch.update_feeds({ choice }, 1, { force = true })
      --    end)
      -- end
   end,

   complete = function()
      return feedlist(feeds)
   end,
   context = { all = true },
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
      ui.refresh { query = table.concat(args, " ") }
   end
end

function M._menu()
   local items = M._list_commands()
   nui.select(items, {
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

function M._sync_feedlist()
   for _, v in ipairs(Config.feeds) do
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

function M._register_autocmds()
   local augroup = vim.api.nvim_create_augroup("Feed", {})
   vim.api.nvim_create_autocmd("User", {
      pattern = "ShowEntryPost",
      group = augroup,
      callback = function()
         local buf = vim.api.nvim_get_current_buf()
         vim.cmd "set cmdheight=0"
         if Config.colorscheme then
            vim.cmd.colorscheme(Config.colorscheme)
         end

         for rhs, lhs in pairs(Config.keys.entry) do
            vim.keymap.set("n", lhs, M[rhs].impl, { buffer = buf, noremap = true })
         end
         for key, value in pairs(Config.options.entry) do
            pcall(vim.api.nvim_set_option_value, key, value, { buf = buf })
            pcall(vim.api.nvim_set_option_value, key, value, { win = vim.api.nvim_get_current_win() })
         end

         local conform_ok, conform = pcall(require, "conform")

         if conform_ok then
            vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
            pcall(conform.format, { formatter = { "injected" }, filetype = "markdown", bufnr = buf })
            vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
         else
            vim.lsp.buf.format { bufnr = buf }
         end
      end,
   })

   vim.api.nvim_create_autocmd("User", {
      pattern = "ShowIndexPost",
      group = augroup,
      callback = function(_)
         vim.cmd "set cmdheight=0"
         local buf = vim.api.nvim_get_current_buf()
         local win = vim.api.nvim_get_current_win()

         for rhs, lhs in pairs(Config.keys.index) do
            vim.keymap.set("n", lhs, M[rhs].impl, { buffer = buf, noremap = true })
         end
         for key, value in pairs(Config.options.index) do
            pcall(vim.api.nvim_set_option_value, key, value, { buf = buf })
            pcall(vim.api.nvim_set_option_value, key, value, { win = win })
         end
         if Config.colorscheme then
            vim.cmd.colorscheme(Config.colorscheme)
         end
      end,
   })
end

return M
