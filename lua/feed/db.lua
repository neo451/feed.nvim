local Path = require "plenary.path"
local config = require "feed.config"
local search = require "feed.search"
local ut = require "feed.utils"

local pdofile = ut.pdofile
local save_file = ut.save_file
local read_file = ut.read_file
local remove_file = function(fp)
   if vim.fs.rm then
      vim.fs.rm(fp, { recursive = true })
   else
      vim.fn.delete(fp, "rf")
   end
end

local db_mt = { __class = "feed.db" }
local db_dir = vim.fs.normalize(config.db_dir)

local data_dir = db_dir .. "/data/"
local object_dir = db_dir .. "/object/"
local feed_fp = db_dir .. "/feeds.lua"
local log_fp = db_dir .. "/log.lua"

---@return feed.db
function db_mt.new()
   local dir_handle = Path:new(db_dir)
   if not dir_handle:is_dir() then
      dir_handle:mkdir { parents = true }
   end
   local data_dir_handle = Path:new(data_dir)
   if not data_dir_handle:is_dir() then
      data_dir_handle:mkdir { parents = true }
   end
   local object_dir_handle = Path:new(object_dir)
   if not object_dir_handle:is_dir() then
      object_dir_handle:mkdir { parents = true }
   end
   local feeds_path = Path:new(feed_fp)
   if not feeds_path:is_file() then
      feeds_path:touch()
      feeds_path:write("return " .. vim.inspect {}, "w")
   end
   local log_path = Path:new(log_fp)
   if not log_path:is_file() then
      log_path:touch()
      log_path:write("return " .. vim.inspect {}, "w")
   end

   local feeds = pdofile(feed_fp)
   local log = pdofile(log_fp)
   return setmetatable({ feeds = feeds, dir = db_dir, log = log }, db_mt)
end

local function if_path(k)
   return vim.fs.find({ k }, { path = db_dir .. "/object/", type = "file" })[1]
end

local mem = {}

function db_mt:__index(k)
   if rawget(db_mt, k) then
      return db_mt[k]
   else
      local r = mem[k]
      if not r then
         local path = if_path(k)
         if path then
            r = pdofile(path)
            mem[k] = r
         end
      end
      return r
   end
end

---@param entry feed.entry
function db_mt:add(entry)
   if if_path(entry.id) then
      return
   end
   local content = entry.content
   entry.content = nil
   local id = entry.id
   entry.id = nil
   save_file(data_dir .. id, content)
   save_file(object_dir .. id, "return " .. vim.inspect(entry))
end

function db_mt:rm(id)
   remove_file(data_dir .. id)
   remove_file(object_dir .. id)
end

function db_mt:iter()
   return vim.iter(vim.fs.dir(object_dir)):map(function(id)
      local r = pdofile(object_dir .. id)
      mem[id] = r
      return id, r
   end)
end

---return a list of db ids base on query
---@param query string
---@return string[]
function db_mt:filter(query)
   local q = search.parse_query(query)
   return search.filter(self, q)
end

---@param id string
---@return string?
function db_mt:read_entry(id)
   return read_file(data_dir .. id)
end

---@param id string
---@return boolean
function db_mt:save_entry(id)
   return save_file(object_dir .. id, "return " .. vim.inspect(self[id]))
end

---@return boolean
function db_mt:save_feeds()
   return save_file(feed_fp, "return " .. vim.inspect(self.feeds))
end

function db_mt:save_err(type, url)
   if not self.log[type] then
      self.log[type] = {}
   end
   table.insert(self.log[type], url)
   return save_file(log_fp, "return " .. vim.inspect(self.log))
end

-- TOOD: metadate file
-- self.feeds.lastUpdated = os.time() -- TODO: opt to update time only after fetch -- TODO: put somewhre?...

function db_mt:blowup()
   remove_file(db_dir)
end

return db_mt
