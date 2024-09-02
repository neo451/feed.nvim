---@class rss.db
---@field index rss.entry[]

local ut = require "rss.utils"
local config = require "rss.config"
local sha1 = require "rss.sha1"
local date = require "rss.date"

local db = { __class = "rss.db" }
db.__index = db

---@param path string
---@param content string
local function save_file(path, content)
   local f = io.open(path, "w")
   return f and f:write(content)
end

---@param path string
---@return string?
local function load_file(path)
   local f = io.open(path, "r")
   return f and f:read("*a"):gsub("\n", "")
end

---@param path string
---@return table?
local function load_page(path)
   local str = load_file(path)
   if str then
      local res = loadstring("return " .. str)
      return res and res()
   end
end

---@param id integer
---@return boolean
function db:if_stored(id)
   for p in vim.iter(vim.fs.dir(self.dir .. "/data/")) do
      if id == p then
         return true
      end
   end
   return false
end

---@param entry rss.entry
function db:add(entry)
   local id = sha1(entry.link)
   if self:if_stored(id) then
      -- print "duplicate keys!!!!"
      return
   end
   entry.id = id
   local content = entry.description
   entry.description = nil
   table.insert(self.index, entry)
   save_file(self.dir .. "/data/" .. id, content)
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

---@param entry rss.entry
---@return table
function db:get(entry)
   return load_file(self.dir .. "/data/" .. entry.id)
end

function db:save()
   save_file(self.dir .. "/index", vim.inspect(self.index))
end

function db:blowup()
   vim.fn.delete(self.dir, "rf")
end

local index_header = { version = "0.1" }

---@param dir string
---@return table
local function make_index(dir)
   save_file(dir, vim.inspect(index_header))
   return index_header
end

---@param dir string
return function(dir)
   dir = vim.fn.expand(dir)
   if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir)
   end
   if vim.fn.isdirectory(dir .. "/data") then
      vim.fn.mkdir(dir .. "/data", "p")
   end
   local index_path = dir .. "/index"
   local index = load_page(index_path)
   if not index then
      index = make_index(index_path)
   end
   return setmetatable({ dir = dir, index = index, ids = ids }, db)
end
