local Path = require "plenary.path"
local config = require "feed.config"
local opml = require "feed.opml"
local search = require "feed.search"
local ut = require "feed.utils"

local pdofile = ut.pdofile
local save_file = ut.save_file

local db_mt = { __class = "feed.db" }
local db_dir = vim.fs.normalize(config.db_dir)

local data_dir = db_dir .. "/data/"
local feed_fp = db_dir .. "/feeds.lua"

local function if_path(k)
   return vim.fs.find({ k }, { path = db_dir .. "/data/", type = "file" })[1]
end

local dir_handle = Path:new(db_dir)
if not dir_handle:is_dir() then
   dir_handle:mkdir { parents = true }
end
local data_dir_handle = Path:new(data_dir)
if not data_dir_handle:is_dir() then
   data_dir_handle:mkdir { parents = true }
end
local feeds_path = Path:new(feed_fp)
if not feeds_path:is_file() then
   feeds_path:touch()
   feeds_path:write("return " .. vim.inspect {}, "w")
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
   save_file(self.dir .. "/data/" .. entry.id, "return " .. vim.inspect(entry))
end

function db_mt:rm(entry)
   vim.fs.rm(self.dir .. "/data/" .. entry.id)
end

function db_mt:iter()
   return vim.iter(vim.fs.dir(self.dir .. "/data/")):map(function(id)
      local r = pdofile(self.dir .. "/data/" .. id)
      mem[id] = r
      return r
   end)
end

---return a list of db ids base on query
---@param query string
---@return string[]
function db_mt:filter(query)
   local q = search.parse_query(query)
   return search.filter(self, q)
end

-- TODO: better save
function db_mt:save(opts)
   opts = opts or {}
   self.feeds.lastUpdated = os.time() -- TODO: opt to update time only after fetch -- TODO: put somewhre?...
   setmetatable(self.feeds, nil)
   save_file(self.dir .. "/feeds.lua", "return " .. vim.inspect(self.feeds))
   setmetatable(self.feeds, opml.mt)
end

function db_mt:blowup()
   vim.fs.rm(self.dir, { recursive = true })
end

local feeds = pdofile(db_dir .. "/feeds.lua")
setmetatable(feeds, opml.mt)

return setmetatable({
   dir = db_dir,
   feeds = feeds,
   mem = mem,
}, db_mt)
