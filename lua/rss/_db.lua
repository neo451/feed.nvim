---@class rss.db
---@field entries rss.entry[]
---@field index string[]

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

function db:__index(k)
	-- if vim.fn.readfile
end

function db:iter()
	local path = self.dir .. "/" .. "data/"
	for name in vim.fs.dir(path) do
		print(name)
		vim.fn.readfile(path .. name)
	end
end

function db:save(path)
	for k, v in pairs(db) do
		store_page(self.dir .. "/" .. self.entries[k], path)
	end
end

return function(dir)
	if not vim.fn.isdirectory(dir) then
		vim.fn.mkdir(dir, "p") -- necessary?
		vim.fn.mkdir(dir .. "/data", "p")
		vim.fn.writefile({ vim.inspect({ version = "0.1" }) }, dir .. "/index")
	end
	setmetatable({ dir = dir, entries = {}, index = {} }, db)
	return db
end
