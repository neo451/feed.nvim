---@class rss.db
---@field entries rss.entry[]
---@field index string[]

local ut = require("rss.utils")
local config = require("rss.config")
local sha1 = require("rss.sha1")
local date = require("rss.date")

local db = { __class = "rss.db" }
db.__index = db

local function store_page(path, page)
	if type(page) == "table" then
		local f = io.open(path, "wb")
		if f then
			f:write("return " .. vim.inspect(page))
			f:close()
			return true
		end
	end
	return false
end

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
	return loadstring("return " .. f)()
end

---@param entry rss.entry
function db:add(entry)
	local id = sha1(entry.link)
	entry.time = date.new_from_entry(entry.pubDate):absolute() -- TODO:
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

function db:sort()
	table.sort(self.index, function(a, b)
		return a.time < b.time
	end)
end

-- function db:__index(id)
-- 	db.entries[id] = load_page(self.dir .. "/data/" .. id)
-- 	return rawget(db.entries, id)
-- 	-- if vim.fn.readfile
-- end

function db:iter()
	local path = self.dir .. "/data/"
	for name in vim.fs.dir(path) do
		print(name)
		vim.fn.readfile(path .. name)
	end
end

function db:map(f)
	for k, v in pairs(self.entries) do
		db[k] = f(k, v)
	end
end

---
function db:save()
	vim.fn.writefile({ vim.inspect(self.index) }, self.dir .. "/index", "b")
end

-- vim.inspect

---@param dir string
return function(dir)
	dir = vim.fn.expand(dir)
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir .. "/data", "p")
		local res = vim.fn.writefile({ vim.inspect({ version = "0.1" }) }, dir .. "/index", "b")
		if res == -1 then
			print("failed to write index file")
		end
	end
	local index = load_page(dir .. "/index")
	return setmetatable({ dir = dir, entries = {}, index = index, index_handle = nil }, db)
end
