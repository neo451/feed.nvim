local config = require "feed.config"

local ut = require "feed.utils"
local db = ut.require "feed.db"
local render = require "feed.render"
local fetch = require "feed.fetch"
local opml = require "feed.parser.opml"

local read_file = ut.read_file
local save_file = ut.save_file

local ui_input = ut.cb_to_co(function(cb, opts)
   pcall(vim.ui.input, opts, vim.schedule_wrap(cb))
end)

local ui_select = ut.cb_to_co(function(cb, items, opts)
   pcall(vim.ui.select, items, opts, cb)
end)

local function list_feeds()
   local ret = {}
   for _, v in ipairs(config.feeds) do
      local url = type(v) == "table" and v[1] or v
      local name = type(v) == "table" and v.name or nil
      local tags = type(v) == "table" and v.tags or nil
      if not db.feeds[url] then
         ret[#ret + 1] = { url, name, tags }
      end
   end
   for url, v in pairs(db.feeds) do
      if type(v) == "table" then
         ret[#ret + 1] = { url, v.title, v.tags }
      end
   end
   return ret
end

local cmds = {}

local function wrap(f)
   return function(...)
      coroutine.wrap(f)(...)
   end
end

-- TODO:
-- cmds.log = {
--    impl = function()
--       local buf = vim.api.nvim_create_buf(false, true)
--       local lines = vim.fn.readfile(vim.fn.stdpath "data" .. "/feed.nvim.log")
--       vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
--       vim.api.nvim_set_current_buf(buf)
--    end,
--    context = { all = true },
-- }

cmds.load_opml = {
   impl = function(fp)
      fp = fp or ui_input { prompt = "path to your opml: ", completion = "file_in_path" }
      if fp then
         fp = vim.fn.expand(fp)
         local str = read_file(fp)
         if str then
            local outlines = opml.import(str)
            if outlines then
               for k, v in pairs(outlines) do
                  db.feeds[k] = v
               end
            else
               ut.notify("opml", { msg = "failed to parse your opml file", level = "ERROR" })
            end
            db:save_feeds()
         else
            ut.notify("opml", { msg = "failed to open your opml file", level = "ERROR" })
         end
      else
         ut.notify("opml", { msg = "failed to find your opml file", level = "ERROR" })
      end
   end,
   context = { all = true },
}

cmds.export_opml = {
   impl = function(fp)
      fp = fp or ui_input { prompt = "export your opml to: ", completion = "file_in_path" }
      fp = vim.fn.expand(fp)
      if not fp then
         return
      end
      local str = opml.export(db.feeds)
      local ok = save_file(fp, str)
      if not ok then
         ut.notify("commands", { msg = "failed to open your expert path", level = "INFO" })
      end
   end,
   context = { all = true },
}

local function native(q)
   render.state.query = q
   table.insert(render.query_history, q)
   render.refresh()
end

cmds.search = {
   impl = function(query)
      if query then
         native(query)
      else
         local ok = pcall(vim.cmd.Telescope, "feed")
         if not ok then
            query = ui_input { prompt = "Search: " }
            native(query)
         end
      end
   end,
   context = { all = true },
}

-- TODO: Native one with nui
cmds.grep = {
   impl = function()
      local ok = pcall(vim.cmd.Telescope, "feed_grep")
      if not ok then
         ut.notify("commands", { msg = "need telescope.nvim and rg to grep feeds", level = "INFO" })
      end
   end,
   context = { all = true },
}

cmds.refresh = {
   impl = function()
      render.refresh()
   end,
   context = { index = true },
}

cmds.show_in_browser = {
   impl = function()
      local entry = render.get_entry()
      if entry then
         local link = entry.link
         if link then
            cmds.untag.impl "unread"
            vim.ui.open(link)
         end
      end
   end,
   context = { index = true, entry = true },
}

cmds.show_in_split = {
   impl = function()
      vim.cmd(config.split_cmd)
      render.show_entry()
      render.state.in_split = true
   end,
   context = { index = true },
}

cmds.show_entry = {
   impl = function()
      render.show_entry()
   end,
   context = { index = true },
}

cmds.show_index = {
   impl = function()
      render.show_index()
   end,
   context = { all = true },
}

cmds.show_next = {
   impl = function()
      if render.current_index == #render.on_display then
         return
      end
      render.show_entry { row_idx = render.current_index + 1 }
   end,
   context = { entry = true },
}

cmds.show_prev = {
   impl = function()
      if render.current_index == 1 then
         return
      end
      render.show_entry { row_idx = render.current_index - 1 }
   end,
   context = { entry = true },
}

cmds.quit = {
   impl = function()
      render.quit()
   end,
   context = { entry = true, index = true },
}

cmds.link_to_clipboard = {
   impl = function()
      vim.fn.setreg("+", render.get_entry().link)
   end,
   context = { index = true, entry = true },
}

cmds.tag = {
   impl = function(tag)
      local entry, id, row = render.get_entry()
      tag = tag or ui_input { prompt = "Tag: " }
      if not tag or not id then
         return
      end
      db:tag(id, tag)
      local buf = vim.api.nvim_get_current_buf()
      if buf == render.state.index_buf then
         render.refresh()
         --    render.show_line(render.state.index_buf, entry, row)
      end
   end,
   context = { index = true, entry = true },
}

--- TODO: make tag untag dot repeatable, undoable, visual line mode
cmds.untag = {
   impl = function(tag)
      local entry, id, row = render.get_entry()
      tag = tag or ui_input { prompt = "Untag: " }
      if not tag or not id then
         return
      end
      db:untag(id, tag)
      local buf = vim.api.nvim_get_current_buf()
      if buf == render.state.index_buf then
         render.refresh()
         --    render.show_line(render.state.index_buf, entry, row)
      end
   end,
   context = { index = true, entry = true },
   -- TODO: completion for in-db tags , tags.lua
}

cmds.open_url = {
   impl = function()
      vim.cmd.normal "yi["
      local text = vim.fn.getreg "0"
      print(text)
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
   end,
   context = { entry = true },
}

cmds.urlview = {
   impl = function()
      local items = render.state.urls
      local item = ui_select(items, {
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
   end,
   context = { entry = true },
}

cmds.list = {
   impl = function()
      local feedlist = list_feeds()
      for _, v in ipairs(feedlist) do
         if v[3] then
            print(v[2], v[1], vim.inspect(v[3]))
         else
            print(v[2], v[1])
         end
      end
   end,
   context = { all = true },
}

cmds.update = {
   impl = function()
      local feedlist = list_feeds()
      fetch.batch_update_feed(feedlist, 100)
   end,
   context = { all = true },
}

---add a feed to database, currently need to actully fetch the feed to be permanent
cmds.add_feed = {
   impl = function(url, name, tags)
      url = url or ui_input { prompt = "Feed url: " }
      name = name or ui_input { prompt = "Feed name (optional): " }
      tags = tags or ui_input { prompt = "Feed tags (optional, comma seperated): " } -- TODO: auto tags
      if url and url ~= "" then
         if tags then
            table.insert(config.feeds, { url, name = name, tags = ut.comma_sp(tags) })
         elseif name then
            table.insert(config.feeds, { url, name = name })
         else
            table.insert(config.feeds, url)
         end
      end
   end,
   context = { all = true },
}

cmds.update_feed = {
   impl = function(name)
      name = name
         or ui_select(list_feeds(), {
            prompt = "Feed to update",
            format_item = function(item)
               return item[2] or item[1]
            end,
         })
      if not name then
         return
      end
      if type(name) == "string" then
         -- TODO: check url or name
         -- name = { name, name }
      end
      fetch.update_feed(name, 1)
   end,

   complete = function()
      return vim.iter(list_feeds())
         :map(function(v)
            return v[2] or v[1]
         end)
         :totable()
   end,
   context = { all = true },
}

cmds.remove = {
   -- TODO: use docstring
   doc = "remove a feed from feedlist, but not its entries",
   impl = function(feed)
      feed = feed or ui_select(list_feeds(), {
         prompt = "Feed to remove",
         format_item = function(item)
            return item[2]
         end,
      })
      if not feed then
         return
      end
      db.feeds[feed[1]] = nil
      db:save_feeds()
   end,
   context = { all = true },
}

cmds.prune = {
   doc = "remove a feed from feedlist, and all its entries",
   impl = function(feed)
      feed = feed or ui_select(list_feeds(), {
         prompt = "Feed to remove",
         format_item = function(item)
            return item[2]
         end,
      })
      if not feed then
         return
      end
      db.feeds[feed[1]] = nil
      db:save_feeds()
      for id, entry in db:iter() do
         if entry.feed == feed[1] then
            db:rm(id)
         end
      end
   end,
   context = { all = true },
}

function cmds._get_item_by_context()
   local buf = vim.api.nvim_get_current_buf()
   local choices = vim.iter(vim.tbl_keys(cmds)):filter(function(v)
      return v:sub(0, 1) ~= "_"
   end)
   if render.state.entry_buf == buf then
      choices = choices:filter(function(v)
         return cmds[v].context.entry or cmds[v].context.all
      end)
   elseif render.state.index_buf == buf then
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

---@param args string[]
function cmds._load_command(args)
   local cmd = table.remove(args, 1)
   if cmds[cmd] then
      local item = cmds[cmd]
      wrap(item.impl)(unpack(args))
   else
      native(table.concat(args, " "))
   end
end

function cmds._menu()
   local items = cmds._get_item_by_context()
   vim.ui.select(items, { prompt = "Feed commands" }, function(choice)
      if choice then
         local item = cmds[choice]
         wrap(item.impl)()
      end
   end)
end

local augroup = vim.api.nvim_create_augroup("Feed", {})

function cmds._register_autocmds()
   vim.api.nvim_create_autocmd("User", {
      pattern = "ShowEntryPost",
      group = augroup,
      callback = function(ev)
         vim.cmd "set cmdheight=0"
         config.on_attach { index = render.state.index_buf, entry = render.state.entry_buf }
         if config.colorscheme then
            vim.cmd.colorscheme(config.colorscheme)
         end
         ut.highlight_entry(ev.buf)
         local conform_ok, conform = pcall(require, "conform")
         -- local has_null_ls, null_ls = pcall(require, "null-ls")
         -- local null_ls_ok = has_null_ls and (null_ls.builtins.formatting["markdownfmt"] or null_ls.builtins.formatting["mdformat"] or null_ls.builtins.formatting["markdownlint"])

         if conform_ok then
            vim.api.nvim_set_option_value("modifiable", true, { buf = ev.buf })
            pcall(conform.format, { formatter = { "injected" }, filetype = "markdown", bufnr = ev.buf })
            print "formated"
            vim.api.nvim_set_option_value("modifiable", false, { buf = ev.buf })
         else
            pcall(vim.lsp.buf.format, { bufnr = render.state.entry_buf }) -- TODO:
         end

         if config.enable_default_keybindings then
            local function eset(lhs, rhs)
               vim.keymap.set("n", lhs, wrap(rhs.impl), { buffer = ev.buf, noremap = true })
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
            pcall(vim.api.nvim_set_option_value, key, value, { buf = ev.buf })
            pcall(vim.api.nvim_set_option_value, key, value, { win = vim.api.nvim_get_current_win() })
         end
      end,
   })

   vim.api.nvim_create_autocmd("User", {
      pattern = "ShowIndexPost",
      group = augroup,
      callback = function(ev)
         vim.cmd "set cmdheight=0"
         config.on_attach { index = render.state.index_buf, entry = render.state.entry_buf }
         if config.colorscheme then
            vim.cmd.colorscheme(config.colorscheme)
         end
         if config.enable_default_keybindings then
            local function iset(lhs, rhs)
               vim.keymap.set("n", lhs, wrap(rhs.impl), { buffer = ev.buf, noremap = true })
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
            pcall(vim.api.nvim_set_option_value, key, value, { buf = ev.buf })
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
