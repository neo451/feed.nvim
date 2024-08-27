local M = {}
local utf8 = require("rss.utf8")

local lpeg = vim.lpeg
-- TODO: handle cjk .. all non-ascii, emojis??
local hans = lpeg.C(lpeg.utfR(0x4E00, 0x9FFF) ^ 1)

function M.str_len(str)
	local len = 0
	for _, c in utf8.codes(str) do
		if hans:match(c) then
			len = len + 2
		else
			len = len + 1
		end
	end
	return len
end

local months =
{ Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12 }

---@param str string
---@return string
function M.format_date(str, format)
	local weekday, day, month, year, time, zone = str:match("([%a]+), (%d+) ([%a]+) (%d+) (%d+:%d+:%d+) ([%+%-]%d+)")
	return format:format(year, months[month], day)
end

M.sub = function(str, startidx, endidx)
	local buffer = {}
	local len = 0
	for _, c in utf8.codes(str) do
		len = len + M.str_len(c) -- TODO: wasteful
		buffer[#buffer + 1] = c
		if len >= endidx then
			return table.concat(buffer, "", 1, #buffer - 1)
		end
	end
end

function M.format_title(str, max_len)
	max_len = max_len or 50
	local len = M.str_len(str)
	if len < max_len then
		return str .. string.rep(" ", max_len - len)
	else
		str = M.sub(str, 1, max_len)
		return str .. string.rep(" ", max_len - M.str_len(str))
	end
end

---@param tags string[]
---@return string
function M.format_tags(tags)
	tags = vim.tbl_keys(tags)
	local buffer = { "(" }
	if #tags == 0 then
		return "()"
	end
	for i, tag in pairs(tags) do
		buffer[#buffer + 1] = tag
		if i ~= #tags then
			buffer[#buffer + 1] = ", "
		end
	end
	buffer[#buffer + 1] = ")"
	return table.concat(buffer, "")
end

---@param buf integer
function M.highlight_entry(buf)
	local len = { 6, 5, 7, 5, 5 }
	for i = 0, 4 do
		vim.highlight.range(buf, 1, "Title", { i, 0 }, { i, len[i + 1] })
	end
end

---@param buf integer
function M.highlight_index(buf)
	local len = #vim.api.nvim_buf_get_lines(buf, 0, -1, true) -- TODO: api??
	for i = 0, len do
		vim.highlight.range(buf, 1, "Title", { i, 0 }, { i, 10 })
	end
end

---@alias filterFunc fun(entry: rss.entry): boolean

-- function M.has_tag(title, tag)
-- 	return db[title][tag] ~= nil
-- end

function M.filter(list, cond)
	local filtered = {}
	for _, title in ipairs(list) do
		if cond(list) then
			filtered[#filtered + 1] = title
		end
	end
	return filtered
end

---@param buf integer
---@param lhs string
---@param rhs string | function
function M.push_keymap(buf, lhs, rhs)
	if type(rhs) == "string" then
		vim.api.nvim_buf_set_keymap(buf, "n", lhs, rhs, { noremap = true, silent = true })
	else
		vim.api.nvim_buf_set_keymap(buf, "n", lhs, "", {
			noremap = true,
			silent = true,
			callback = rhs,
		})
	end
end

return M
