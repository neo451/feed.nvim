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
      return a.time > b.time
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

---@param dir string
---@return table
local function make_index(dir)
   save_file(dir, "return " .. vim.inspect(index_header))
   return index_header
end

---@param dir string
local function check_dir(dir)
   dir = vim.fn.expand(dir)
   if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir)
   end
   if vim.fn.isdirectory(dir .. "/data") == 0 then
      vim.fn.mkdir(dir .. "/data", "p")
   end
   local index_path = dir .. "/index"
   if not isFile(index_path) then
      -- print("writing a new index file to " .. index_path)
      make_index(index_path)
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
   check_dir = check_dir,
}
