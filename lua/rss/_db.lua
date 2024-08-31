---@class rss.db
---@field entries rss.entry[]
---@field index string[]

local ut = require("rss.utils")
local config = require("rss.config")
local sha1 = require("rss.sha1")
local date = require("rss.date")

local db = { __class = "rss.db" }
db.__index = db

---@param entry rss.entry
---@return string
local function entry_name(entry)
	local format = "%s %s %s %s"
	-- vim.api.nvim_win_get_width(0) -- TODO: use this or related autocmd to truncate title
	return string.format(
		format,
		tostring(date.new_from_entry(entry.pubDate)),
		ut.format_title(entry.title, config.max_title_length),
		entry.feed,
		ut.format_tags(entry.tags)
	)
end

local function load_page(path)
	local f = table.concat(vim.fn.readfile(path))
	local ok, res = pcall(loadstring, "return " .. f)
	if not ok then
		return "[rss.nvim]: wrong formated table!"
	end
	return res()
end

---@param entry rss.entry
function db:add(entry)
	local id = sha1(entry.link)
	entry.pubDate = date.new_from_entry(entry.pubDate):absolute() -- TODO:
	-- pp(entry)
	entry.id = id
	-- local content = entry["content:encoded"] or entry.description
	local content = entry.description
	entry.description = nil
	table.insert(self.index, entry)
	vim.fn.writefile({ content }, self.dir .. "/data/" .. id)
end

---@param entry rss.entry
function db:address(entry)
	return self.dir .. "/data/" .. entry.id
end

---sort index by time, descending
function db:sort()
	table.sort(self.index, function(a, b)
		return a.pubDate > b.pubDate
	end)
end

function db:save()
	vim.fn.writefile({ vim.inspect(self.index) }, self.dir .. "/index", "b")
end

function db:blowup()
	vim.fn.delete(self.dir, "rf")
end

---@param dir string
return function(dir)
	dir = vim.fn.expand(dir)
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir .. "/data", "p")
		vim.fn.writefile({ vim.inspect({ version = "0.1" }) }, dir .. "/index", "b")
	end
	local index = load_page(dir .. "/index")
	return setmetatable({ dir = dir, index = index }, db)
end
