--- Actions corespond to keymaps

local render = require "rss.render"
local config = require "rss.config"
local index_actions = {}
local entry_actions = {}

local function current_index()
   local index = vim.api.nvim_win_get_cursor(0)[1] - 1
   render.current_index = index
   return index
end

-- leave_index = "<cmd>bd<cr>", --TODO: jump to the buffer before the index
function index_actions.leave_index()
   vim.cmd "bd"
   vim.cmd("colorscheme " .. config.og_colorscheme)
end

-- TODO: for reference
-- local function open_browser(url)
--   local browser_cmd
--   if vim.fn.has('unix') == 1 then
--     if vim.fn.executable('sensible-browser') == 1 then
--       browser_cmd = 'sensible-browser'
--     else
--       browser_cmd = 'xdg-open'
--     end
--   end
--   if vim.fn.has('mac') == 1 then
--     browser_cmd = 'open'
--   end
--   -- TODO: windows support?
--
--   vim.cmd(':silent !' .. browser_cmd .. ' ' .. vim.fn.fnameescape(url))
-- end

function index_actions.open_browser()
   vim.ui.open(render.get_entry(current_index()).link)
end

function index_actions.open_w3m()
   vim.cmd("W3m " .. render.get_entry(current_index()).link)
end

function index_actions.open_entry()
   render.show_entry(current_index())
end

function index_actions.open_split()
   render.state.in_split = true
   vim.cmd(config.split)
   vim.cmd(config.split:find "v" and "wincmd k" or "wincmd j")
   render.show_entry(current_index())
end

function index_actions.link_to_clipboard()
   vim.fn.setreg("+", render.current_entry().link)
end

function index_actions.add_tag()
   local input = vim.fn.input "Tag: "
   render.current_entry().tags[input] = true
   -- db:save() -- TODO: do it on exit or refresh
   render.show_index() -- inefficient??
end

function index_actions.remove_tag()
   local input = vim.fn.input "Tag: "
   render.current_entry().tags[input] = nil
   render.show_index()
end

function entry_actions.back_to_index()
   if render.state.in_split then
      vim.cmd "q"
      render.state.in_split = false
   end
   vim.api.nvim_set_current_buf(render.buf.index)
end

function entry_actions.next_entry()
   if render.current_index == #render.index then
      return
   end
   render.current_index = render.current_index + 1
   render.show_entry(render.current_index)
end

-- TODO: properly do 'ring' navigation, ie. wrap around
function entry_actions.prev_entry()
   if render.current_index == 1 then
      return
   end
   render.current_index = render.current_index - 1
   render.show_entry(render.current_index)
end

return { index = index_actions, entry = entry_actions }
