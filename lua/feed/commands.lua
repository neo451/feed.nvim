local config = require "feed.config"
local db = require "feed.db"
local render = require "feed.render"
local fetch = require "feed.fetch"
local ut = require "feed.utils"
local search = require "feed.search"
local opml = require "feed.opml"

local ui_input = ut.cb_to_co(function(cb, opts)
   pcall(vim.ui.input, opts, vim.schedule_wrap(cb))
end)

local ui_select = ut.cb_to_co(function(cb, items, opts)
   pcall(vim.ui.select, items, opts, cb)
end)

local og_colorscheme, og_buffer
local cmds = {}

local function wrap(f)
   return function()
      coroutine.wrap(f)()
   end
end

local function prepare_bufs()
   if render.buf then
      return
   end
   render.buf = {}
   render.buf.index = vim.api.nvim_create_buf(false, true)
   render.buf.entry = vim.api.nvim_create_buf(false, true)
   vim.api.nvim_buf_set_name(render.buf.index, "FeedIndex")
   vim.api.nvim_buf_set_name(render.buf.entry, "FeedEntry")

   if config.enable_default_keybindings then
      local function iset(lhs, rhs)
         vim.keymap.set("n", lhs, wrap(rhs.impl), { buffer = render.buf.index })
      end
      local function eset(lhs, rhs)
         vim.keymap.set("n", lhs, wrap(rhs.impl), { buffer = render.buf.entry })
      end

      local function bset(lhs, rhs)
         iset(lhs, rhs)
         eset(lhs, rhs)
      end

      iset("<CR>", cmds.show_entry)
      iset("<M-CR>", cmds.show_in_split)
      iset("r", cmds.refresh)

      bset("b", cmds.show_in_browser)
      bset("s", cmds.search)
      bset("y", cmds.link_to_clipboard)
      bset("s", cmds.search)
      bset("+", cmds.tag)
      bset("-", cmds.untag)
      bset("q", cmds.quit)

      eset("u", cmds.urlview)
      eset("}", cmds.show_next)
      eset("{", cmds.show_prev)
      eset("gx", cmds.open_url)
   end
end

cmds._prepare_bufs = prepare_bufs

if not render.state.query then
   render.state.query_string = config.search.default_query
   table.insert(render.state.query_history, config.search.default_query)
   render.state.query = search.parse_query(config.search.default_query)
end

local function merge(user_config_feeds, db_feeds)
   local res = vim.deepcopy(db_feeds)
   for _, v in ipairs(user_config_feeds) do
      local url = type(v) == "table" and v[1] or v
      if not db_feeds[url] then
         res[#res + 1] = v
      end
   end
   return res
end

cmds.log = {
   impl = function()
      local buf = vim.api.nvim_create_buf(false, true)
      local lines = vim.fn.readfile(vim.fn.stdpath "data" .. "/feed.nvim.log")
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_set_current_buf(buf)
   end,
   context = { all = true },
}

cmds.build = {
   impl = function()
      require("feed.build").build()
   end,
   context = { all = true },
}

--@param path string
---@return string?
local function read_file(path)
   local ret
   local f = io.open(path, "r")
   if f then
      ret = f:read "*a"
      f:close()
   else
      return
   end
   return ret
end

cmds.load_opml = {
   impl = function(fp)
      fp = fp or ui_input { prompt = "path to your opml: ", completion = "file_in_path" }
      if fp then
         fp = vim.fn.expand(fp)
         local str = read_file(fp)
         if str then
            local outlines = opml.import(str)
            for _, v in ipairs(outlines) do
               db.feeds:append(v)
            end
            db:save()
         end
      else
         ut.notify("commands", { msg = "failed to find your load file", level = "INFO" })
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
      db.feeds:export(fp)
   end,
   context = { all = true },
}

cmds.search = {
   -- TODO: complete history
   impl = function(query)
      query = query or ui_input { prompt = "Search: " }
      if query then
         render.state.query_string = query
         render.state.query = search.parse_query(query)
         table.insert(render.state.query_history, query)
         render.refresh()
      end
   end,
   context = { index = true },
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
      local link = entry.link
      cmds.untag.impl "unread"
      vim.ui.open(link)
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
      if not render.buf then
         prepare_bufs()
      end
      render.show_entry()
      render.state.in_entry = true
   end,
   context = { index = true },
}

cmds.show_index = {
   impl = function()
      if not render.buf then
         prepare_bufs()
      end
      og_colorscheme = vim.g.colors_name
      og_buffer = vim.api.nvim_get_current_buf()
      render.refresh()
      render.state.in_index = true
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
      if render.state.in_split then
         vim.cmd "q"
         vim.api.nvim_set_current_buf(render.buf.index)
         render.state.in_split = false
         render.state.in_index = true
      elseif render.state.in_entry then
         render.show_index()
         render.state.in_entry = false
         render.state.in_index = true
      elseif render.state.in_index then
         if not og_buffer then
            og_buffer = vim.api.nvim_create_buf(true, false)
         end
         vim.api.nvim_set_current_buf(og_buffer)
         pcall(vim.cmd.colorscheme, og_colorscheme)
         render.state.in_index = false
      end
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
      local id = render.get_entry().id
      tag = tag or ui_input { prompt = "Tag: " }
      if not tag then
         return
      end
      db[id].tags[tag] = true
      db:save()
      render.refresh()
   end,
   context = { index = true, entry = true },
}

cmds.untag = {
   impl = function(tag)
      local id = render.get_entry().id
      tag = tag or ui_input { prompt = "Untag: " }
      if not tag then
         return
      end
      db[id].tags[tag] = nil
      db:save()
      render.refresh()
   end,
   context = { index = true, entry = true },
   -- TODO: completion for in-db tags
   -- complete =
}

--- TOOD:
---@param link any
---@return string
local function resolve_url_from_entry(link)
   local feed = render.get_entry().feed
   local root_url = db.feeds:lookup(feed).htmlUrl
   return ut.url_resolve(root_url, link)
end

cmds.open_url = {
   impl = function()
      vim.cmd.normal "yi["
      local text = vim.fn.getreg "0"
      local item = vim.iter(render.state.urls):find(function(v)
         return v[1] == text
      end)
      if item then
         local link = resolve_url_from_entry(item[2])
         vim.ui.open(link)
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
         local link = resolve_url_from_entry(item[2])
         vim.ui.open(link)
      end
   end,
   context = { entry = true },
}

cmds.list_feeds = {
   impl = function()
      local feedlist = merge(config.feeds, db.feeds)
      for _, v in ipairs(feedlist) do
         print(v.title or v.name, type(v) == "table" and (v.xmlUrl or v[1]) or v)
      end
   end,
   context = { all = true },
}

cmds.update = {
   impl = function()
      local feedlist = merge(config.feeds, db.feeds)
      fetch.batch_update_feed(feedlist, 200)
   end,
   context = { all = true },
}

local function comma_sp(str)
   return vim.iter(vim.gsplit(str, ",")):fold({}, function(acc, v)
      v = v:gsub("%s", "")
      if v ~= "" then
         acc[v] = true
      end
      return acc
   end)
end

---add a feed to database, currently need to actully fetch the feed to be permanent
cmds.add_feed = {
   impl = function(url, name, tags)
      url = url or ui_input { prompt = "Feed url: " }
      name = name or ui_input { prompt = "Feed name (optional): " }
      tags = tags or ui_input { prompt = "Feed tags (optional, comma seperated): " } -- TODO: auto tags
      if url and url ~= "" then
         if tags then
            table.insert(config.feeds, { url, name = name, tags = comma_sp(tags) })
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
      name = name or ui_select(cmds.update_feed.complete(), {})
      if not name then
         return
      end
      local url
      if db.feeds:lookup(name) then
         url = db.feeds:lookup(name)
      else
         url = name
      end
      fetch.update_feed(url, 1)
   end,

   complete = function()
      local names = vim.tbl_keys(db.feeds.names)
      local new_feeds = {}
      for _, v in ipairs(config.feeds) do
         local url = type(v) == "table" and v[1] or v
         if not db.feeds[url] then
            new_feeds[#new_feeds + 1] = url
         end
      end
      vim.list_extend(names, new_feeds)
      return names
   end,
   context = { all = true },
}

local function get_item_by_context()
   local choices = vim.iter(vim.tbl_keys(cmds)):filter(function(v)
      return v:sub(0, 1) ~= "_"
   end)

   if render.state.in_entry then
      choices = choices:filter(function(v)
         return cmds[v].context.entry or cmds[v].context.all
      end)
   elseif render.state.in_index then
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

setmetatable(cmds, {
   __call = function()
      local items = get_item_by_context()
      vim.ui.select(items, { prompt = "Feed commands" }, function(choice)
         if choice then
            local item = cmds[choice]
            coroutine.wrap(function()
               item.impl()
            end)()
         end
      end)
   end,
})

---purge a feed from all of the db, including entries
-- function cmds:prune() end

---remove a feed from db.feeds
-- function cmds:remove_feed() end

--- **INTEGRATIONS**
cmds.telescope = {
   impl = function()
      pcall(vim.cmd.Telescope, "feed")
   end,
   context = { all = true },
}
-- TODO:
cmds.grep = {
   impl = function()
      pcall(vim.cmd.Telescope, "feed_grep")
   end,
   context = { all = true },
}

local augroup = vim.api.nvim_create_augroup("Feed", {})

vim.api.nvim_create_autocmd("BufEnter", {
   group = augroup,
   pattern = "FeedEntry",
   callback = function(ev)
      config.on_attach(render.buf)
      vim.cmd.colorscheme(config.colorscheme)
      pcall(require, "feed.lualine")
      render.state.in_entry = true
      vim.cmd "set cmdheight=0"
      local ok, conform = pcall(require, "conform")
      if ok then
         vim.api.nvim_set_option_value("modifiable", true, { buf = ev.buf })
         pcall(conform.format, { formatter = { "injected" }, filetype = "markdown", bufnr = ev.buf })
         vim.api.nvim_set_option_value("modifiable", false, { buf = ev.buf })
      else
         print(conform)
      end
      for key, value in pairs(config.options.entry) do
         pcall(vim.api.nvim_set_option_value, key, value, { buf = ev.buf })
         pcall(vim.api.nvim_set_option_value, key, value, { win = vim.api.nvim_get_current_win() })
      end
   end,
})

vim.api.nvim_create_autocmd("BufEnter", {
   group = augroup,
   pattern = "FeedIndex",
   callback = function(ev)
      config.on_attach(render.buf)
      vim.cmd.colorscheme(config.colorscheme)
      pcall(require, "feed.lualine")
      vim.cmd "set cmdheight=0"
      for key, value in pairs(config.options.index) do
         pcall(vim.api.nvim_set_option_value, key, value, { buf = ev.buf })
         pcall(vim.api.nvim_set_option_value, key, value, { win = vim.api.nvim_get_current_win() })
      end
   end,
})

vim.api.nvim_create_autocmd("User", {
   pattern = "ShowEntryPost",
   group = augroup,
   callback = function(_)
      ut.highlight_entry(render.buf.entry)
      local conform_ok, conform = pcall(require, "conform")
      -- local has_null_ls, null_ls = pcall(require, "null-ls")
      -- local null_ls_ok = has_null_ls and null_ls.builtins.formatting["markdownfmt"] or
      --     null_ls.builtins.formatting["mdformat"] or null_ls.builtins.formatting["markdownlint"]

      if conform_ok then
         vim.api.nvim_set_option_value("modifiable", true, { buf = render.buf.entry })
         pcall(conform.format, { formatter = { "injected" }, filetype = "markdown", bufnr = render.buf.entry })
         vim.api.nvim_set_option_value("modifiable", false, { buf = render.buf.entry })
         -- elseif null_ls_ok then
         -- vim.lsp.start({})
         -- vim.lsp.buf.format({ bufnr = render.buf.entry })
      end
   end,
})

vim.api.nvim_create_autocmd("User", {
   pattern = "ShowIndexPost",
   group = augroup,
   callback = function(_)
      ut.highlight_index(render.buf.index)
   end,
})

local function restore_state()
   vim.cmd "set cmdheight=1"
   vim.wo.winbar = ""
   vim.cmd.colorscheme(og_colorscheme)
end

vim.api.nvim_create_autocmd("BufLeave", {
   group = augroup,
   pattern = "FeedIndex",
   callback = restore_state,
})

vim.api.nvim_create_autocmd("BufLeave", {
   group = augroup,
   pattern = "FeedEntry",
   callback = restore_state,
})

---@param args string[]
local function load_command(args)
   local cmd = table.remove(args, 1)
   local item = cmds[cmd]
   if type(item) == "table" then
      coroutine.wrap(function()
         item.impl(unpack(args))
      end)()
   elseif type(item) == "function" then
      item(unpack(args))
   end
end

vim.api.nvim_create_user_command("Feed", function(opts)
   pcall(require("telescope").load_extension, "feed")
   pcall(require("telescope").load_extension, "feed_grep")

   if #opts.fargs == 0 then
      cmds()
   else
      load_command(opts.fargs)
   end
end, {
   nargs = "*",
   complete = function(arg_lead, line)
      local subcmd_key, subcmd_arg_lead = line:match "^['<,'>]*Feed*%s(%S+)%s(.*)$"
      if subcmd_key and subcmd_arg_lead and cmds[subcmd_key] and type(cmds[subcmd_key]) == "table" and cmds[subcmd_key].complete then
         local sub_items = cmds[subcmd_key].complete()
         return vim.iter(sub_items)
            :filter(function(arg)
               return arg:find(subcmd_arg_lead) ~= nil
            end)
            :totable()
      end
      if line:match "^['<,'>]*Feed*%s+%w*$" then
         -- Filter subcommands that match
         local subcommand_keys = get_item_by_context()
         return vim.iter(subcommand_keys)
            :filter(function(key)
               return key:find(arg_lead) ~= nil
            end)
            :totable()
      end
   end,
})

-- vim.api.nvim_create_autocmd("WinResized", {
--    group = augroup,
--    buffer = render.buf.entry,
--    callback = function()
--       render.refresh()
--    end,
-- })
--
-- vim.api.nvim_create_autocmd("WinResized", {
--    group = augroup,
--    buffer = render.buf.index,
--    callback = function()
--       render.refresh()
--    end,
-- })

return cmds
