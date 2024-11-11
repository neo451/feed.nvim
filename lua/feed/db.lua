local Path = require "plenary.path"
local config = require "feed.config"
local search = require "feed.search"
local ut = require "feed.utils"

local pdofile = ut.pdofile
local save_file = ut.save_file
local save_obj = function(fp, object)
   save_file(fp, "return " .. vim.inspect(object))
end
local read_file = ut.read_file
local remove_file = function(fp)
   if vim.fs.rm then
      vim.fs.rm(fp, { recursive = true })
   else
      vim.fn.delete(fp, "rf")
   end
end

local build_regex = search.build_regex

local ensure_path = function(fp, type)
   if type == "dir" then
      local dir_handle = Path:new(fp)
      if not dir_handle:is_dir() then
         dir_handle:mkdir { parents = true }
      end
   elseif type == "obj" then
      local feeds_path = Path:new(fp)
      if not feeds_path:is_file() then
         feeds_path:touch()
         feeds_path:write("return " .. vim.inspect {}, "w")
      end
   elseif type == "file" then
      local feeds_path = Path:new(fp)
      if not feeds_path:is_file() then
         feeds_path:touch()
      end
   end
end

local db_mt = { __class = "feed.db" }
local db_dir = vim.fs.normalize(config.db_dir)

local data_dir = db_dir .. "/data/"
local object_dir = db_dir .. "/object/"
local feeds_fp = db_dir .. "/feeds.lua"
local log_fp = db_dir .. "/log.lua"
local tags_fp = db_dir .. "/tags.lua"
local index_fp = db_dir .. "/index"

local append_time_id = function(time, id)
   local f = io.open(index_fp, "a")
   if f then
      f:write(time .. " " .. id .. "\n")
      f:close()
   end
end

local function parse_index()
   local res = {}
   for line in io.lines(index_fp) do
      local time, id = line:match "(%d+)%s(%S+)"
      res[#res + 1] = { id, tonumber(time) }
   end
   return res
end

local mem = {}
---@return feed.db
function db_mt.new()
   ensure_path(db_dir, "dir")
   ensure_path(data_dir, "dir")
   ensure_path(object_dir, "dir")
   ensure_path(feeds_fp, "obj")
   ensure_path(log_fp, "obj")
   ensure_path(tags_fp, "obj")
   ensure_path(index_fp, "file")

   local feeds = pdofile(feeds_fp)
   local log = {}
   local index = parse_index()
   local tags = pdofile(tags_fp)
   return setmetatable({
      dir = db_dir,
      feeds = feeds,
      log = log,
      index = index,
      tags = tags,
      mem = mem,
   }, db_mt)
end

local function if_path(k)
   return vim.fs.find({ k }, { path = db_dir .. "/object/", type = "file" })[1]
end

---@param k any
---@return function | feed.entry | string
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
   table.insert(self.index, { id, entry.time })
   -- TODO: sort here?? messure perf
   append_time_id(entry.time, id)
   -- save_obj(time_fp, self.index)
   save_file(data_dir .. id, content)
   save_obj(object_dir .. id, entry)
end

function db_mt:tag(id, tag)
   if not self[id].tags then
      self[id].tags = {}
   end
   if not self.tags[tag] then
      self.tags[tag] = {}
   end
   self[id].tags[tag] = true
   self.tags[tag][id] = true
   self:save_entry(id)
   save_obj(tags_fp, self.tags)
end

function db_mt:untag(id, tag)
   if not self[id].tags then
      self[id].tags = {}
   end
   if not self.tags[tag] then
      self.tags[tag] = {}
   end
   self[id].tags[tag] = nil
   self.tags[tag][id] = nil
   self:save_entry(id)
   save_obj(tags_fp, self.tags)
end

function db_mt:sort()
   table.sort(self.index, function(a, b)
      return a[2] > b[2]
   end)
end

function db_mt:rm(id)
   for i, v in ipairs(self.index) do
      if v[1] == id then
         table.remove(self.index, i)
      end
   end
   mem[id] = nil
   -- TODO: remove in tags
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
   local iter

   if q.must_have and not vim.tbl_contains(q.must_have, "unread", {}) then
      --- TODO:
      local tt = self.tags[q.must_have[1]]
      if tt then
         local t = vim.tbl_keys(tt)
         table.sort(t, function(a, b)
            return self[a].time > self[b].time
         end)
         iter = vim.iter(t):map(function(id)
            return id, self[id].time
         end)
      else
         iter = vim.iter {}
      end
   else
      self:sort()
      iter = vim.iter(self.index):map(function(v)
         return v[1], v[2]
      end)
   end

   if q.limit then
      iter = iter:take(q.limit)
   end

   if q.before then
      iter:find(function(_, time)
         return time <= q.before
      end)
   end

   if q.after then
      iter:filter(function(_, time)
         return time > q.after
      end)
   end

   if q.must_not_have then
      iter = iter:filter(function(id)
         for _, tag in ipairs(q.must_not_have) do
            if self.tags[tag][id] then
               return false
            end
         end
         return true
      end)
   end

   if q.re then
      iter = iter:filter(function(v)
         local entry = self[v]
         if not entry or not entry.title then
            return false
         end
         for _, reg in ipairs(q.re) do
            local q, rev = build_regex(reg)
            if rev then
               if q:match_str(entry.title) then
                  return false
               end
            else
               if not q:match_str(entry.title) then
                  return false
               end
            end
         end
         return true
      end)
   end

   if q.feed then
      iter = iter:filter(function(v)
         local re, rev = build_regex(q.feed)
         if not re:match_str(self[v].feed) then
            return rev
         end
         return true
      end)
   end

   return iter:fold({}, function(acc, id)
      mem[id] = pdofile(object_dir .. id)
      acc[#acc + 1] = id
      return acc
   end)
end

---@param id string
---@return string?
function db_mt:read_entry(id)
   return read_file(data_dir .. id)
end

---@param id string
---@param obj table
---@return boolean
function db_mt:save_entry(id, obj)
   return save_obj(object_dir .. id, obj or self[id])
end

---@return boolean
function db_mt:save_feeds()
   return save_file(feeds_fp, "return " .. vim.inspect(self.feeds))
end

function db_mt:save_err(type, url, mes)
   if not self.log[type] then
      self.log[type] = {}
   end
   self.log[type][url] = mes or true
   return save_file(log_fp, "return " .. vim.inspect(self.log))
end

-- TOOD: metadate file
-- self.feeds.lastUpdated = os.time() -- TODO: opt to update time only after fetch -- TODO: put somewhre?...

function db_mt:blowup()
   remove_file(db_dir)
end

return db_mt.new()
