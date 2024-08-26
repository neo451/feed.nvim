-- from https://github.com/uleelx/FlatDB
local function isFile(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

local function isDir(path)
	path = string.gsub(path .. "/", "//", "/")
	local ok, err, code = os.rename(path, path)
	if ok or code == 13 then
		return true
	end
	return false
end

local function load_page(path)
	local ret
	local f = io.open(path, "rb")
	if f then
		-- ret = vim.mpack.decode(f:read("*a"))
		ret = loadstring(f:read("*a"))
		f:close()
	end
	return ret
end

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

local pool = {}

local db_funcs = {
	save = function(db, p)
		if p then
			if type(p) == "string" and type(db[p]) == "table" then
				return store_page(pool[db] .. "/" .. p, db[p])
			else
				return false
			end
		end
		for p, page in pairs(db) do
			if not store_page(pool[db] .. "/" .. p, page) then
				return false
			end
		end
		return true
	end,
}

local mt = {
	__index = function(db, k)
		if db_funcs[k] then
			return db_funcs[k]
		end
		if isFile(pool[db] .. "/" .. k) then
			db[k] = load_page(pool[db] .. "/" .. k)
		end
		return rawget(db, k)
	end,
}

pool.hack = db_funcs

return setmetatable(pool, {
	__mode = "kv",
	__call = function(pool, path)
		assert(isDir(path), path .. " is not a directory.")
		if pool[path] then
			return pool[path]
		end
		local db = {}
		setmetatable(db, mt)
		pool[path] = db
		pool[db] = path
		return db
	end,
})
