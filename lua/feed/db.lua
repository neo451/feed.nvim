local Path = require "plenary.path"
local config = require "feed.config"
local opml = require "feed.opml"

local index_header = { version = "0.3" }

---@param dir string
local function prepare_db(dir)
   dir = vim.fs.normalize(config.db_dir)
   local dir_handle = Path:new(dir)
   if not dir_handle:is_dir() then
      dir_handle:mkdir()
   end
   local data_dir_handle = Path:new(dir .. "/data")
   if not data_dir_handle:is_dir() then
      data_dir_handle:mkdir()
   end
   local index_path = Path:new(dir .. "/index.lua")
   if not index_path:is_file() then
      index_path:touch()
      index_path:write("return " .. vim.inspect(index_header), "w")
   end
   return dir
end

local db_mt = { __class = "feed.db" }
db_mt.__index = function(self, k)
   if not rawget(self, k) then
      if rawget(db_mt, k) then
         return db_mt[k]
      elseif rawget(self.index, k) then
         return self.index[k]
      end
   end
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
---@return string
local function get_file(path)
   local ret
   local f = io.open(path, "rb")
   if f then
      ret = f:read "*a"
      f:close()
   end
   return ret
end

---@param entry feed.entry
function db_mt:add(entry)
   if self.index[entry.id] then
      return
   end
   local content = entry.content
   entry.content = nil
   self.index[entry.id] = entry
   save_file(self.dir .. "/data/" .. entry.id, content)
end

local function pdofile(fp)
   local ok, res = pcall(dofile, fp)
   if ok and res then
      return res
   end
end

---@param entry feed.entry
---@return string?
function db_mt:get(entry)
   return get_file(self.dir .. "/data/" .. entry.id)
end

-- TODO: better save
function db_mt:save(opts)
   opts = opts or {}
   self.index.lastUpdated = os.time() -- TODO: opt to update time only after fetch
   setmetatable(self.feeds, nil)
   save_file(self.dir .. "/index.lua", "return " .. vim.inspect(self.index))
   save_file(self.dir .. "/feeds.lua", "return " .. vim.inspect(self.feeds))
   setmetatable(self.feeds, opml.mt)
end

function db_mt:blowup()
   vim.fn.delete(self.dir, "rf")
end

local dir = prepare_db(config.db_dir)
local index = pdofile(dir .. "/index.lua")
local feeds = pdofile(dir .. "/feeds.lua")

if not feeds then
   feeds = opml.new()
else
   setmetatable(feeds, opml.mt)
end

return setmetatable({
   dir = dir,
   index = index,
   feeds = feeds,
}, db_mt)
