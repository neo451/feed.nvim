local config = require "feed.config"
local db = require "feed.db"
local render = require "feed.render"
local fetch = require "feed.fetch"
local ut = require "feed.utils"
local search = require "feed.search"
local opml = require "feed.opml"

local ui_input = ut.cb_to_co(function(cb, items)
   vim.ui.input(items, cb)
end)

local ui_select = ut.cb_to_co(function(cb, items, opts)
   vim.ui.select(items, opts, cb)
end)

local og_colorscheme, og_buffer

local cmds = {}

if not render.state.query then
   render.state.query_string = config.search.default_query
   table.insert(render.state.query_history, config.search.default_query)
   render.state.query = search.parse_query(config.search.default_query)
end

local function merge(user_config_feeds, db_feeds)
   local res = vim.deepcopy(db_feeds)
   for _, v in ipairs(user_config_feeds) do
      local url = type(v) == "table" and v[1] or v
      if not db_feeds:has(url) then
         res[#res + 1] = v
      end
   end
   return res
end

-- function cmds.blowup()
--    db:blowup()
-- end

cmds.log = {
   impl = function()
      local buf = vim.api.nvim_create_buf(false, true)
      local lines = vim.fn.readfile(vim.fn.stdpath "data" .. "/feed.nvim.log")
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_set_current_buf(buf)
   end,
   context = { all = true },
}

-- TODO: ui completion done, what about command line completion ?
cmds.load_opml = {
   ---load opml file to list of sources
   ---@param fp string
   impl = function(fp)
      fp = fp or ui_input { prompt = "path to your opml: ", completion = "file_in_path" }
      if not fp then
         return
      end
      fp = vim.fn.expand(fp)
      local f = io.open(fp, "r")
      if f then
         local str = f:read "*a"
         local outlines = opml.import(str)
         for _, v in ipairs(outlines) do
            db.feeds:append(v)
         end
         db:save()
      else
         ut.notify("commands", { msg = "failed to find your opml file", level = "ERROR" })
      end
   end,
   context = "all",
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
   context = "all",
}

cmds.search = {
   impl = function()
      local query = ui_input { prompt = "Search: " }
      if query then
         render.state.query_string = query
         render.state.query = search.parse_query(query) -- TODO: preserve history, and allow direct pass arg or new input window, up/down for history
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
      vim.ui.open(link)
   end,
   context = { index = true, entry = true },
}

cmds.show_in_split = {
   impl = function()
      vim.cmd(config.layout.split)
      render.show_entry()
      render.state.in_split = true
   end,
   context = { index = true },
}

cmds.show_entry = {
   impl = function()
      render.show_entry()
      render.state.in_entry = true
   end,
   context = { index = true },
}

cmds.quit = {
   impl = function()
      if render.state.in_split then
         vim.cmd "q"
         vim.api.nvim_set_current_buf(render.buf.index)
         render.state.in_split = false
      elseif render.state.in_entry then
         print "here"
         render.show_index()
         render.state.in_entry = false
      else
         if not og_buffer then
            og_buffer = vim.api.nvim_create_buf(true, false)
         end
         vim.api.nvim_set_current_buf(og_buffer)
         pcall(vim.cmd.colorscheme, og_colorscheme)
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
   impl = function()
      local id = render.get_entry().id
      local input = ui_input { prompt = "Untag: " }
      if not input then
         return
      end
      render.untag(id, input)
   end,
   context = { index = true, entry = true },
}

cmds.untag = {
   impl = function()
      local id = render.get_entry().id
      local input = ui_input { prompt = "Untag: " }
      if not input then
         return
      end
      render.untag(id, input)
   end,
   context = { index = true, entry = true },
}

cmds.show_index = {
   --- entry buffer actions
   impl = function()
      og_colorscheme = vim.g.colors_name
      og_buffer = vim.api.nvim_get_current_buf()
      render.refresh()
   end,
   context = { all = true },
}

cmds.quit_index = {
   impl = function()
      if not og_buffer then
         og_buffer = vim.api.nvim_create_buf(true, false)
      end
      vim.api.nvim_set_current_buf(og_buffer)
      vim.cmd.colorscheme(og_colorscheme)
   end,
   context = { index = true },
}

-- TODO:
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

-- TODO: better view
cmds.list_feeds = {
   impl = function()
      for _, v in ipairs(db.feeds) do
         print(v.title, v.xmlUrl)
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

-- TODO: use a local feeds file, no need to have fetched to be permanant
---add a feed to database, currently need to actully fetch the feed to be permanent
cmds.add_feed = {
   impl = coroutine.wrap(function()
      local feed_url = ui_input { prompt = "Feed url: " }
      local feed_name = ui_input { prompt = "Feed name (optional): " }
      -- local feed_tags = input { prompt = "Feed tags (optional, comma seperated): " } -- TODO:
      if feed_url and feed_url ~= "" then
         if feed_name then
            table.insert(config.feeds, { feed_url, name = feed_name })
         end
         table.insert(config.feeds, feed_url)
      end
   end),
   context = { all = true },
}

---remove a feed from db.feeds
-- function cmds:remove_feed() end

cmds.update_feed = {
   impl = coroutine.wrap(function(name)
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
   end),

   complete = function()
      local names = vim.tbl_keys(db.feeds.names) -- TODO: the feeds in config
      local new_feeds = {}
      for _, v in ipairs(config.feeds) do
         local url = type(v) == "table" and v[1] or v
         if not db.feeds.names[url] then
            new_feeds[#new_feeds + 1] = url
         end
      end
      vim.list_extend(names, new_feeds)
      return names
   end,
   context = { all = true },
}

setmetatable(cmds, {
   __call = function()
      local choices = vim.tbl_keys(cmds)
      if render.state.in_entry then
         choices = vim.iter(choices)
            :filter(function(v)
               return cmds[v].context.entry
            end)
            :totable()
      elseif vim.api.nvim_get_current_buf() == render.buf.index then
         choices = vim.iter(choices)
            :filter(function(v)
               return cmds[v].context.index
            end)
            :totable()
      else
         choices = vim.iter(choices)
            :filter(function(v)
               return cmds[v].context.all
            end)
            :totable()
      end

      vim.ui.select(choices, {}, function(choice)
         if choice then
            local item = cmds[choice]
            coroutine.wrap(item.impl)()
         end
      end)
   end,
})

---purge a feed from all of the db, including entries
-- function cmds:prune() end

--- **INTEGRATIONS**
cmds.telescope = {
   impl = function()
      pcall(vim.cmd.Telescope, "feed")
   end,
   context = { all = true },
}

cmds.grep = {
   impl = function()
      pcall(vim.cmd.Telescope, "feed_grep")
      pcall(vim.cmd.Telescope, "feed")
   end,
   context = { all = true },
}

render.prepare_bufs()

local augroup = vim.api.nvim_create_augroup("Feed", {})

vim.api.nvim_create_autocmd("BufEnter", {
   group = augroup,
   buffer = render.buf.entry,
   callback = function(ev)
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
      for key, value in pairs(config.entry.opts) do
         pcall(vim.api.nvim_set_option_value, key, value, { buf = ev.buf })
         pcall(vim.api.nvim_set_option_value, key, value, { win = vim.api.nvim_get_current_win() })
      end
      -- TODO: user callback from here callback(ev: { ev, win, entry })
   end,
})

vim.api.nvim_create_autocmd("BufEnter", {
   group = augroup,
   buffer = render.buf.index,
   callback = function(ev)
      vim.cmd.colorscheme(config.colorscheme)
      pcall(require, "feed.lualine")
      vim.cmd "set cmdheight=0"
      for key, value in pairs(config.index.opts) do
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
      -- TODO: args = { lines: string[], ... }
      local conform_ok, conform = pcall(require, "conform")
      -- local has_null_ls, null_ls = pcall(require, "null-ls")
      -- local null_ls_ok = has_null_ls and null_ls.builtins.formatting["markdownfmt"] or
      --     null_ls.builtins.formatting["mdformat"] or null_ls.builtins.formatting["markdownlint"]

      if conform_ok then
         vim.api.nvim_set_option_value("modifiable", true, { buf = render.buf.entry })
         pcall(conform.format, { formatter = { "injected" }, filetype = "markdown", bufnr = render.buf.entry })
         vim.api.nvim_set_option_value("modifiable", false, { buf = render.buf.entry })
         -- elseif null_ls_ok then
         --    -- vim.lsp.start({})
         --    -- TODO:
         --    vim.lsp.buf.format({ bufnr = render.buf.entry })
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
   buffer = render.buf.index,
   callback = restore_state,
})

vim.api.nvim_create_autocmd("BufLeave", {
   group = augroup,
   buffer = render.buf.entry,
   callback = restore_state,
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
