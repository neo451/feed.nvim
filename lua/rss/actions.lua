--- Actions corespond to keymaps

local render = require("rss.render")
local config = require("rss.config")
local index_actions = {
	leave_index = "<cmd>bd<cr>", --TODO: jump to the buffer before the index
}
local entry_actions = {}

function index_actions.open_browser()
	vim.ui.open(render.current_entry().link)
end

function index_actions.open_w3m()
	vim.cmd("W3m " .. render.current_entry().link)
end

function index_actions.open_entry()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	render.current_index = row
	render.render_entry(row)
end

function index_actions.open_split()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	render.state.in_split = true
	render.current_index = row
	vim.cmd(config.split)
	vim.cmd(config.split:find("v") and "wincmd k" or "wincmd j")
	render.render_entry(row)
end

function index_actions.link_to_clipboard()
	vim.fn.setreg("+", render.current_entry().link)
end

function index_actions.add_tag()
	local input = vim.fn.input("Tag: ")
	render.current_entry().tags[input] = true
	-- db:save() -- TODO: do it on exit or refresh
	render.render_index() -- inefficient??
end

function index_actions.remove_tag()
	local input = vim.fn.input("Tag: ")
	render.current_entry().tags[input] = nil
	render.render_index()
end

function entry_actions.back_to_index()
	if render.state.in_split then
		vim.cmd("q")
		render.state.in_split = false
	end
	vim.api.nvim_set_current_buf(render.buf.index)
end

function entry_actions.next_entry()
	if render.current_index == #render.index then
		return
	end
	render.current_index = render.current_index + 1
	render.render_entry(render.current_index)
end

-- TODO: properly do 'ring' navigation, ie. wrap around
function entry_actions.prev_entry()
	if render.current_index == 1 then
		return
	end
	render.current_index = render.current_index - 1
	render.render_entry(render.current_index)
end

return { index = index_actions, entry = entry_actions }
