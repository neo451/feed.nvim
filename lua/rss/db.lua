---@class rss.db
---@field index rss.entry[]

local ut = require "rss.utils"
local config = require "rss.config"
local sha1 = require "rss.sha1"
local date = require "rss.date"

local db = { __class = "rss.db" }
db.__index = db

---@param path any
---@return table | boolean
local function load_page(path)
   local f = io.open(path, "r"):read "*a"
   if f then
      local ok, res = pcall(loadstring, "return " .. f)
      if not ok then
         return false
      end
      return res and res()
   else
      return false
   end
end

---@param path string
---@return string | boolean
local function load_file(path)
   local f = io.open(path, "r"):read "*a"
   f = f:gsub("\n", "")
   if f then
      return f
   else
      return false
   end
end

---@param path string
---@param content string
---@return boolean
local function save_file(path, content)
   local f = io.open(path, "w")
   if f then
      f:write(content)
      return true
   else
      return false
   end
end

---@param entry rss.entry
function db:add(entry)
   local id = sha1(entry.link)
   entry.id = id
   --- TODO: put the logic elsewhere
   -- local content = entry["content:encoded"] or entry.description
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
   index.version = "0.1" -- TODO: weirddd
   return setmetatable({ dir = dir, index = index }, db)
end
