local Path = require "plenary.path"
local db_mt = { __class = "feed.db" }
db_mt.__index = db_mt

local function isFile(path)
   local f = io.open(path, "r")
   if f then
      f:close()
      return true
   end
   return false
end

---@param path string
---@param content string
local function save_file(path, content)
   local f = io.open(path, "wb")
   if f then
      f:write(content)
      f:close()
   end
end

---@param path string
---@return string?
local function get_file(path)
   local ret
   local f = io.open(path, "rb")
   if f then
      ret = f:read "*a"
      f:close()
   end
   return ret
end

---@param id integer
---@return boolean
function db_mt:is_stored(id)
   for p in vim.iter(vim.fs.dir(self.dir .. "/data/")) do
      if id == p then
         return true
      end
   end
   return false
end

---@param entry feed.entry
---@param content string
function db_mt:add(entry, content)
   if self:is_stored(entry.id) then
      -- print "duplicate keys!!!!"
      return
   end
   table.insert(self.index, entry)
   save_file(self.dir .. "/data/" .. entry.id, content)
end

---@param entry feed.entry
---@return string
function db_mt:address(entry)
   return self.dir .. "/data/" .. entry.id
end

---sort index by time, descending
function db_mt:sort()
   table.sort(self.index, function(a, b)
      if a.time and b.time then
         return a.time > b.time
      end
      return true -- HACK:
   end)
end

function db_mt:update_index()
   self.index = loadfile(self.dir .. "/index")()
end

---@param entry feed.entry
---@return table
function db_mt:get(entry)
   return get_file(self.dir .. "/data/" .. entry.id)
end

function db_mt:save()
   save_file(self.dir .. "/index", "return " .. vim.inspect(self.index))
end

function db_mt:blowup()
   vim.fn.delete(self.dir, "rf")
end

local index_header = { version = "0.1" }

-- TODO: support windows, but planery.path does not.. make pull request..

---@param dir string
local function prepare_db(dir)
   dir = Path:new(dir):expand()
   local dir_handle = Path:new(dir)
   local data_dir_handle = Path:new(dir .. "/data")
   if not dir_handle:is_dir() then
      dir_handle:mkdir()
   end
   if not data_dir_handle:is_dir() then
      data_dir_handle:mkdir()
   end
   local index_path = Path:new(dir .. "/index")
   if not index_path:is_file() then
      index_path:touch()
      index_path:write("return " .. vim.inspect(index_header), "w")
   end
end

---@param dir string
local function db(dir)
   dir = vim.fn.expand(dir)
   local index_path = dir .. "/index"
   local index = loadfile(index_path)()
   return setmetatable({ dir = dir, index = index }, db_mt)
end

return {
   db = db,
   prepare_db = prepare_db,
}
