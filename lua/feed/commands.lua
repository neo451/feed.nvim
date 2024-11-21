local config = require "feed.config"
local ut = require "feed.utils"
local db = ut.require "feed.db"
local render = require "feed.render"
local fetch = require "feed.fetch"
local opml = require "feed.parser.opml"
local feeds = db.feeds

local read_file = ut.read_file
local save_file = ut.save_file
local wrap = ut.wrap
local input = ut.input
local select = ut.select

local cmds = {}

cmds.log = {
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

cmds.load_opml = {
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

cmds.export_opml = {
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

cmds.search = {
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
cmds.grep = {
   doc = "full-text search through the entry contents (experimental)",
   impl = function()
      local ok = pcall(vim.cmd.Telescope, "feed_grep")
      if not ok then
         ut.notify("commands", { msg = "need telescope.nvim and rg to grep feeds", level = "INFO" })
      end
   end,
   context = { all = true },
}

cmds.refresh = {
   doc = "re-renders the index buffer",
   impl = function()
      render.refresh {}
   end,
   context = { index = true },
}

cmds.show_in_browser = {
   doc = "open entry link in browser with vim.ui.open",
   impl = function()
      local entry = render.get_entry()
      if entry then
         local link = entry.link
         if link then
            cmds.untag.impl "unread"
            vim.ui.open(link)
         end
      else
         ut.notify("show_in_browser", { msg = "no link for entry you try to open", level = "INFO" })
      end
   end,
   context = { index = true, entry = true },
}

cmds.show_in_split = {
   doc = "show entry in split",
   impl = function()
      vim.cmd(config.split_cmd)
      render.show_entry()
      render.state.in_split = true
   end,
   context = { index = true },
}

cmds.show_entry = {
   doc = "show entry in new buffer",
   impl = function()
      render.show_entry()
   end,
   context = { index = true },
}

cmds.show_index = {
   doc = "show query results in new buffer",
   impl = render.show_index,
   context = { all = true },
}

cmds.show_next = {
   doc = "show next query result",
   impl = function()
      if render.current_index == #render.on_display then
         return
      end
      render.show_entry { row_idx = render.current_index + 1 }
   end,
   context = { entry = true },
}

cmds.show_prev = {
   doc = "show previous query result",
   impl = function()
      if render.current_index == 1 then
         return
      end
      render.show_entry { row_idx = render.current_index - 1 }
   end,
   context = { entry = true },
}

cmds.quit = {
   doc = "quit current view",
   impl = render.quit,
   context = { entry = true, index = true },
}

cmds.link_to_clipboard = {
   doc = "yank link to system clipboard",
   impl = function()
      vim.fn.setreg("+", render.get_entry().link)
   end,
   context = { index = true, entry = true },
}

cmds.tag = {
   doc = "tag an entry",
   impl = wrap(function(tag)
      local _, id, _ = render.get_entry()
      tag = tag or input { prompt = "Tag: " }
      if not tag or not id then
         return
      end
      db:tag(id, tag)
      local buf = vim.api.nvim_get_current_buf()
      if buf == render.index then
         render.refresh()
      end
   end),
   context = { index = true, entry = true },
}

--- TODO: make tag untag dot repeatable, undoable, visual line mode
cmds.untag = {
   doc = "untag an entry",
   impl = wrap(function(tag)
      local _, id, _ = render.get_entry()
      tag = tag or input { prompt = "Untag: " }
      if not tag or not id then
         return
      end
      db:untag(id, tag)
      local buf = vim.api.nvim_get_current_buf()
      if buf == render.index then
         render.refresh()
      end
   end),
   context = { index = true, entry = true },
   -- TODO: completion for in-db tags , tags.lua
}

cmds.open_url = {
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

cmds.urlview = {
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

cmds.list = {
   doc = "list all feeds",
   impl = function()
      for _, url in ipairs(vim.tbl_keys(feeds)) do
         print(feeds[url] and feeds[url].title or url, url, feeds[url] and feeds[url].tags and vim.inspect(feeds[url].tags))
      end
   end,
   context = { all = true },
}

cmds.update = {
   doc = "update all feeds",
   impl = function()
      fetch.update_feeds(vim.tbl_keys(feeds), 10)
   end,
   context = { all = true },
}

cmds.update_feed = {
   doc = "update a feed to db",
   impl = wrap(function(url)
      url = url
         or select(vim.tbl_keys(feeds), {
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
      return vim.tbl_keys(feeds)
   end,
   context = { all = true },
}

-- TODO:
cmds.prune_feed = {
   doc = "remove a feed from feedlist, and all its entries",
   impl = wrap(function(url)
      url = url
         or select(vim.tbl_keys(feeds), {
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

function cmds._list_commands()
   local buf = vim.api.nvim_get_current_buf()
   local choices = vim.iter(vim.tbl_keys(cmds)):filter(function(v)
      return v:sub(0, 1) ~= "_"
   end)
   if render.entry == buf then
      choices = choices:filter(function(v)
         return cmds[v].context.entry or cmds[v].context.all
      end)
   elseif render.index == buf then
      choices = choices:filter(function(v)
         return cmds[v].context.index or cmds[v].context.all
      end)
   else
      choices = choices:filter(function(v)
         return cmds[v].context.all
      end)
   end
   return choices:totable()
end

function cmds._load_command(args)
   local cmd = args[1]
   if cmds[cmd] then
      table.remove(args, 1)
      local item = cmds[cmd]
      item.impl(unpack(args))
   else
      render.refresh { query = table.concat(args, " ") }
   end
end

function cmds._menu()
   local items = cmds._list_commands()
   vim.ui.select(items, {
      prompt = "Feed commands",
      format_item = function(item)
         return item .. ": " .. cmds[item].doc
      end,
   }, function(choice)
      if choice then
         local item = cmds[choice]
         item.impl()
      end
   end)
end

function cmds._sync_feedlist()
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

function cmds._register_autocmds()
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
         local conform_ok, conform = pcall(require, "conform")
         -- local has_null_ls, null_ls = pcall(require, "null-ls")
         -- local null_ls_ok = has_null_ls and (null_ls.builtins.formatting["markdownfmt"] or null_ls.builtins.formatting["mdformat"] or null_ls.builtins.formatting["markdownlint"])

         if conform_ok then
            vim.api.nvim_set_option_value("modifiable", true, { buf = render.entry })
            pcall(conform.format, { formatter = { "injected" }, filetype = "markdown", bufnr = render.entry })
            vim.api.nvim_set_option_value("modifiable", false, { buf = render.entry })
         else
            pcall(vim.lsp.buf.format, { bufnr = render.entry }) -- TODO:
         end

         if config.enable_default_keybindings then
            local function eset(lhs, rhs)
               vim.keymap.set("n", lhs, rhs.impl, { buffer = render.entry, noremap = true })
            end
            eset("b", cmds.show_in_browser)
            eset("s", cmds.search)
            eset("+", cmds.tag)
            eset("-", cmds.untag)
            eset("q", cmds.quit)
            eset("r", cmds.urlview)
            eset("}", cmds.show_next)
            eset("{", cmds.show_prev)
            eset("gx", cmds.open_url)
         end
         for key, value in pairs(config.options.entry) do
            pcall(vim.api.nvim_set_option_value, key, value, { buf = render.entry })
            pcall(vim.api.nvim_set_option_value, key, value, { win = vim.api.nvim_get_current_win() })
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
            iset("<CR>", cmds.show_entry)
            iset("<M-CR>", cmds.show_in_split)
            iset("r", cmds.refresh)
            iset("b", cmds.show_in_browser)
            iset("s", cmds.search)
            iset("y", cmds.link_to_clipboard)
            iset("+", cmds.tag)
            iset("-", cmds.untag)
            iset("q", cmds.quit)
         end
         for key, value in pairs(config.options.index) do
            pcall(vim.api.nvim_set_option_value, key, value, { buf = render.index })
            pcall(vim.api.nvim_set_option_value, key, value, { win = vim.api.nvim_get_current_win() })
         end
      end,
   })

   local function restore_state()
      vim.cmd "set cmdheight=1"
      vim.wo.winbar = "" -- TODO: restore the user's old winbar is there is
   end

   -- vim.api.nvim_create_autocmd("User", {
   --    group = augroup,
   --    pattern = "QuitEntryPost",
   --    callback = restore_state,
   -- })

   vim.api.nvim_create_autocmd("User", {
      group = augroup,
      pattern = "QuitIndexPost",
      callback = restore_state,
   })
end

return cmds
