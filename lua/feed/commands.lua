--- TODO: lazy load these ...
local config = require "feed.config"
local fetch = require "feed.fetch"
local feedparser = require "feed.feedparser"
local render = require "feed.render"
local ut = require "feed.utils"
local db = require("feed.db").db(config.db_dir)

local cmds = {}

-- TODO:
-- 1. unjam: stop the connection pool?
-- 2. add_feed: add to database
-- 3. db_unload: not needed? file handles are just closed... but is that efficient?
-- 4. load_opml: need to load locally
-- 5. export_opml
-- 6. tag / untag: save to db
-- 7. show: its a better name lol

---load opml file to list of sources
---@param file string
cmds.load_opml = {
   impl = function(file)
      local feeds = feedparser.parse(file, { type = "opml" })
      for _, feed in ipairs(feeds) do
         local title = feed.title
         local xmlUrl = feed.xmlUrl
         table.insert(config.feeds, { xmlUrl, name = title })
      end
   end,
   complete = function(lead)
      local tab = { "abc", "efg", "hijk" }
      return vim.iter(tab):filter(function(t)
         return t:find(lead) ~= nil
      end)
   end,
}

local function Fee(opts)
   local fargs = opts.fargs
   local sub_key = table.remove(fargs, 1)
   local sub_cmd = cmds[sub_key]
   if not sub_cmd then
      vim.notify("Feed: Unknown command: " .. sub_key, vim.log.levels.ERROR)
   end
   sub_cmd.impl(fargs, opts)
end

vim.api.nvim_create_user_command("Fee", Fee, {
   nargs = "+",
   desc = "Feed comp test",
   complete = function(arg_lead, cmdline, _)
      print(arg_lead)
   end,
})

---index buffer commands
function cmds.show_in_browser()
   vim.ui.open(render.current_entry().link)
end

function cmds.show_in_w3m()
   if ut.check_command "W3m" then
      vim.cmd("W3m " .. render.current_entry().link)
   else
      vim.notify "[rss.nvim]: need w3m.nvim installed"
   end
end

local function current_index()
   local index = vim.api.nvim_win_get_cursor(0)[1] - 1
   render.current_index = index
   return index
end

function cmds.show_in_split()
   render.state.in_split = true
   vim.cmd(config.split)
   vim.cmd(config.split:find "v" and "wincmd k" or "wincmd j")
   render.show_entry(current_index())
end

function cmds.show_entry()
   render.state.in_entry = true
   render.show_entry(current_index())
end

function cmds.link_to_clipboard()
   vim.fn.setreg("+", render.current_entry().link)
end

function cmds.tag()
   local input = vim.fn.input "Tag: "
   render.current_entry().tags[input] = true
   -- db:save() -- TODO: do it on exit / or only if ":w" , make an option
   render.show_index() -- TODO: inefficient??, only rerender the one entry
end

function cmds.untag()
   local input = vim.fn.input "Untag: "
   render.current_entry().tags[input] = nil
   render.show_index()
end

function cmds.quit_index()
   --TODO: jump to the buffer before the index
   --- TODO: check if in index
   if ut.check_command "ZenMode" then
      vim.cmd "ZenMode"
   end
   vim.cmd "bd"
   vim.cmd.colorscheme(config.og_colorscheme)
   render.rendered_once = false
end

--- entry buffer actions
function cmds.show_index()
   if not render.state.in_entry then
      if not render.buf.index then
         print "reerer"
         render.prepare_bufs(cmds)
      end
      render.show_index()
   else
      if render.state.rendered_once then
         if render.state.in_split then
            vim.cmd "q"
            render.state.in_split = false
         else
            vim.api.nvim_set_current_buf(render.buf.index)
         end
      end
   end
end

function cmds.show_next()
   if render.current_index == #db.index then
      return
   end
   render.current_index = render.current_index + 1
   render.show_entry(render.current_index)
end

-- TODO: properly do 'ring' navigation, ie. wrap around
function cmds.show_prev()
   if render.current_index == 1 then
      return
   end
   render.current_index = render.current_index - 1
   render.show_entry(render.current_index)
end

function cmds.list_feeds()
   print(vim.inspect(vim.tbl_values(config.feeds)))
end

function cmds.update()
   local ok, progress = pcall(require, "fidget.progress")
   local handle
   if not ok then
      vim.notify "fidget not found" -- TODO: make a simple message printer if fidget not found...
   else
      handle = progress.handle.create {
         title = "Feed update",
         message = "fetching feeds...",
         percentage = 0,
      }
   end
   for i, link in ipairs(config.feeds) do
      fetch.update_feed(link, #config.feeds, handle)
   end
   db:sort() -- TODO:
   db:save()
end

---add a feed to database
---@param str string
function cmds:add_feed(str) end

-- function cmds.update_feed(name)
--    fetch.update_feed(config.feeds[name], 1, 1)
-- end

function cmds:telescope()
   if ut.check_command "Telescope" then
      vim.cmd "Telescope rss"
   end
end

function cmds.which_key()
   local wk = require "which-key"
   wk.show {
      buf = 0,
      ["local"] = true,
      loop = true,
   }
end

---@param args string[]
local function load_command(args)
   local cmd = table.remove(args, 1)
   return cmds[cmd](unpack(args))
end

local popup = require "plenary.popup"

-- --- Display the keymaps of registered actions similar to which-key.nvim.<br>
-- --- - Notes:
-- ---   - The defaults can be overridden via |action_generate.which_key|.
-- ---@param prompt_bufnr number: The prompt bufnr
-- actions.which_key = function(prompt_bufnr, opts)
--    opts = opts or {}
--    opts.max_height = vim.F.if_nil(opts.max_height, 0.4)
--    opts.only_show_current_mode = vim.F.if_nil(opts.only_show_current_mode, true)
--    opts.mode_width = vim.F.if_nil(opts.mode_width, 1)
--    opts.keybind_width = vim.F.if_nil(opts.keybind_width, 7)
--    opts.name_width = vim.F.if_nil(opts.name_width, 30)
--    opts.line_padding = vim.F.if_nil(opts.line_padding, 1)
--    opts.separator = vim.F.if_nil(opts.separator, " -> ")
--    opts.close_with_action = vim.F.if_nil(opts.close_with_action, true)
--    opts.normal_hl = vim.F.if_nil(opts.normal_hl, "TelescopePrompt")
--    opts.border_hl = vim.F.if_nil(opts.border_hl, "TelescopePromptBorder")
--    opts.winblend = vim.F.if_nil(opts.winblend, conf.winblend)
--    opts.column_padding = vim.F.if_nil(opts.column_padding, "  ")
--
--    -- Assigning into 'opts.column_indent' would override a number with a string and
--    -- cause issues with subsequent calls, keep a local copy of the string instead
--    local column_indent = table.concat(utils.repeated_table(vim.F.if_nil(opts.column_indent, 4), " "))
--
--    -- close on repeated keypress
--    local km_bufs = (function()
--       local ret = {}
--       local bufs = a.nvim_list_bufs()
--       for _, buf in ipairs(bufs) do
--          for _, bufname in ipairs { "_TelescopeWhichKey", "_TelescopeWhichKeyBorder" } do
--             if string.find(a.nvim_buf_get_name(buf), bufname) then
--                table.insert(ret, buf)
--             end
--          end
--       end
--       return ret
--    end)()
--    if not vim.tbl_isempty(km_bufs) then
--       for _, buf in ipairs(km_bufs) do
--          utils.buf_delete(buf)
--          local win_ids = vim.fn.win_findbuf(buf)
--          for _, win_id in ipairs(win_ids) do
--             pcall(a.nvim_win_close, win_id, true)
--          end
--       end
--       return
--    end
--
--    local displayer = entry_display.create {
--       separator = opts.separator,
--       items = {
--          { width = opts.mode_width },
--          { width = opts.keybind_width },
--          { width = opts.name_width },
--       },
--    }
--
--    local make_display = function(mapping)
--       return displayer {
--          { mapping.mode,    vim.F.if_nil(opts.mode_hl, "TelescopeResultsConstant") },    --TODO:
--          { mapping.keybind, vim.F.if_nil(opts.keybind_hl, "TelescopeResultsVariable") }, --TODO:
--          { mapping.name,    vim.F.if_nil(opts.name_hl, "TelescopeResultsFunction") },    --TODO:
--       }
--    end
--
--    local mappings = config.keymaps.index
--
--    -- table.sort(mappings, function(x, y)
--    --    if x.name < y.name then
--    --       return true
--    --    elseif x.name == y.name then
--    --       -- show normal mode as the standard mode first
--    --       if x.mode > y.mode then
--    --          return true
--    --       else
--    --          return false
--    --       end
--    --    else
--    --       return false
--    --    end
--    -- end)
--
--    local entry_width = #opts.column_padding + opts.mode_width + opts.keybind_width + opts.name_width +
--    (3 * #opts.separator)
--    local num_total_columns = math.floor((vim.o.columns - #column_indent) / entry_width)
--    opts.num_rows = math.min(math.ceil(#mappings / num_total_columns),
--       resolver.resolve_height(opts.max_height)(_, _, vim.o.lines))
--    local total_available_entries = opts.num_rows * num_total_columns
--    local winheight = opts.num_rows + 2 * opts.line_padding
--
--    -- -- place hints at top or bottom relative to prompt
--    -- local win_central_row = function(win_nr)
--    --    return a.nvim_win_get_position(win_nr)[1] + 0.5 * a.nvim_win_get_height(win_nr)
--    -- end
--    -- -- TODO(fdschmidt93|l-kershaw): better generalization of where to put which key float
--    -- local picker = action_state.get_current_picker(prompt_bufnr)
--    -- local prompt_row = win_central_row(picker.prompt_win)
--    -- local results_row = win_central_row(picker.results_win)
--    -- local preview_row = picker.preview_win and win_central_row(picker.preview_win) or results_row
--    -- local prompt_pos = prompt_row < 0.4 * vim.o.lines or
--    -- prompt_row < 0.6 * vim.o.lines and results_row + preview_row < vim.o.lines
--    --
--    -- local modes = { n = "Normal", i = "Insert" }
--    -- local title_mode = opts.only_show_current_mode and modes[mode] .. " Mode " or ""
--    local title_text = title_mode .. "Keymaps"
--    local popup_opts = {
--       relative = "editor",
--       enter = false,
--       minwidth = vim.o.columns,
--       maxwidth = vim.o.columns,
--       minheight = winheight,
--       maxheight = winheight,
--       line = prompt_pos == true and vim.o.lines - winheight + 1 or 1,
--       col = 0,
--       border = { prompt_pos and 1 or 0, 0, not prompt_pos and 1 or 0, 0 },
--       borderchars = { prompt_pos and "─" or " ", "", not prompt_pos and "─" or " ", "", "", "", "", "" },
--       noautocmd = true,
--       title = { { text = title_text, pos = prompt_pos and "N" or "S" } },
--    }
--    local km_win_id, km_opts = popup.create("", popup_opts)
--    local km_buf = a.nvim_win_get_buf(km_win_id)
--    a.nvim_buf_set_name(km_buf, "_TelescopeWhichKey")
--    a.nvim_buf_set_name(km_opts.border.bufnr, "_TelescopeTelescopeWhichKeyBorder")
--    a.nvim_win_set_option(km_win_id, "winhl", "Normal:" .. opts.normal_hl)
--    a.nvim_win_set_option(km_opts.border.win_id, "winhl", "Normal:" .. opts.border_hl)
--    a.nvim_win_set_option(km_win_id, "winblend", opts.winblend)
--    a.nvim_win_set_option(km_win_id, "foldenable", false)
--
--    vim.api.nvim_create_autocmd("BufLeave", {
--       buffer = km_buf,
--       once = true,
--       callback = function()
--          pcall(vim.api.nvim_win_close, km_win_id, true)
--          pcall(vim.api.nvim_win_close, km_opts.border.win_id, true)
--          require("telescope.utils").buf_delete(km_buf)
--       end,
--    })
--
--    a.nvim_buf_set_lines(km_buf, 0, -1, false, utils.repeated_table(opts.num_rows + 2 * opts.line_padding, column_indent))
--
--    local keymap_highlights = a.nvim_create_namespace "telescope_whichkey"
--    local highlights = {}
--    for index, mapping in ipairs(mappings) do
--       local row = utils.cycle(index, opts.num_rows) - 1 + opts.line_padding
--       local prev_line = a.nvim_buf_get_lines(km_buf, row, row + 1, false)[1]
--       if index == total_available_entries and total_available_entries > #mappings then
--          local new_line = prev_line .. "..."
--          a.nvim_buf_set_lines(km_buf, row, row + 1, false, { new_line })
--          break
--       end
--       local display, display_hl = make_display(mapping)
--       local new_line = prev_line .. display .. opts.column_padding -- incl. padding
--       a.nvim_buf_set_lines(km_buf, row, row + 1, false, { new_line })
--       table.insert(highlights, { hl = display_hl, row = row, col = #prev_line })
--    end
--
--    -- highlighting only after line setting as vim.api.nvim_buf_set_lines removes hl otherwise
--    for _, highlight_tbl in pairs(highlights) do
--       local highlight = highlight_tbl.hl
--       local row_ = highlight_tbl.row
--       local col = highlight_tbl.col
--       for _, hl_block in ipairs(highlight) do
--          a.nvim_buf_add_highlight(km_buf, keymap_highlights, hl_block[2], row_, col + hl_block[1][1],
--             col + hl_block[1][2])
--       end
--    end
--
--    -- only set up autocommand after showing preview completed
--    if opts.close_with_action then
--       vim.schedule(function()
--          vim.api.nvim_create_autocmd("User", {
--             pattern = "TelescopeKeymap",
--             once = true,
--             callback = function()
--                pcall(vim.api.nvim_win_close, km_win_id, true)
--                pcall(vim.api.nvim_win_close, km_opts.border.win_id, true)
--                require("telescope.utils").buf_delete(km_buf)
--             end,
--          })
--       end)
--    end
-- end

-- IDEAS:
-- show random entry
-- show entry from (feed, url, tag, fuzzy find)

return {
   load_command = load_command,
   cmds = cmds,
}

-- vim.api.nvim_create_autocmd("VimLeavePre", {
--    pattern = "*.md",
--    callback = function()
--       print "leave!"
--       db:save()
--       -- autocmds.update()
--    end,
-- })
