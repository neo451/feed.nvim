local Path = require("feed.db.path")
local Config = require("feed.config")
local query = require("feed.db.query")
local ut = require("feed.utils")
local uv = vim.uv

---@class feed.db
---@field dir feed.path
---@field feeds feed.opml
---@field index table
---@field tags table<string, table<string, boolean>>
---@field add fun(db: feed.db, entry: feed.entry, tags: string[]?)
---@field rm fun(db: feed.db, id: string)
---@field iter fun(db: feed.db, sort: boolean?): Iter
---@field filter fun(db: feed.db, query: string) : string[]
---@field save_feeds fun(db: feed.db)
---@field save_index fun(db: feed.db)
---@field save_tags fun(db: feed.db)
---@field tag fun(db: feed.db, id: string, tag: string | string[])
---@field untag fun(db: feed.db, id: string, tag: string | string[])
---@field blowup fun(db: feed.db)
---@field update fun(db: feed.db)
---@field lastUpdated fun(db: feed.db): string
local M = {}

---@param fp feed.path
---@param t any
local ensure_exists = function(fp, t)
   if not uv.fs_stat(tostring(fp)) then
      if t == "dir" then
         Path.mkdir(fp)
      elseif t == "file" then
         Path.save(fp, "")
      elseif t == "obj" then
         Path.save(fp, {})
      end
   end
end

local function if_path(k, dir)
   return vim.fs.find({ k }, { path = tostring(dir / "object"), type = "file" })[1]
end

local function load_index(fp)
   local res = {}
   fp = tostring(fp)
   if not uv.fs_stat(fp) then
      return {}
   end
   local f = io.open(fp, "r")
   assert(f)
   for line in f:lines() do
      local time, id = line:match("(%d+)%s(%S+)")
      res[#res + 1] = { id, tonumber(time) }
   end
   return res
end

local mem = {}

---@return feed.db
function M.new(dir)
   dir = Path.new(dir or Config.db_dir)
   local data_dir = dir / "data"
   local object_dir = dir / "object"
   local feeds_fp = dir / "feeds.lua"
   local tags_fp = dir / "tags.lua"
   local index_fp = dir / "index"

   ensure_exists(dir, "dir")
   ensure_exists(data_dir, "dir")
   ensure_exists(object_dir, "dir")
   ensure_exists(feeds_fp, "obj")
   ensure_exists(tags_fp, "obj")
   ensure_exists(index_fp, "file")

   return setmetatable({
      dir = dir,
      index = load_index(dir / "index"),
      feeds = feeds_fp:load(),
      tags = setmetatable(tags_fp:load(), {
         __index = function(t, tag)
            rawset(t, tag, {})
            return rawget(t, tag)
         end,
      }),
   }, M)
end

---@param k any
---@return function | feed.entry
function M:__index(k)
   local ms = rawget(M, k)
   if ms then
      return ms
   end
   local r = mem[k]
   if not r then
      r = Path.load(self.dir / "object" / k)
      mem[k] = r
   end
   return r
end

---@param id string
---@param entry feed.entry
function M:__newindex(id, entry)
   if not id or if_path(id, self.dir) then
      return
   end
   mem[id] = entry
   local time = entry.time
   table.insert(self.index, { id, time })
   Path.append(self.dir / "index", time .. " " .. id .. "\n")
   Path.save(self.dir / "object" / id, entry)
end

function M:update()
   local feeds = Path.load(self.dir / "feeds.lua")
   rawset(self, "feeds", feeds)
   local index = load_index(self.dir / "index")
   rawset(self, "index", index)
   local tags = Path.load(self.dir / "tags.lua")
   setmetatable(tags, {
      __index = function(t, tag)
         rawset(t, tag, {})
         return rawget(t, tag)
      end,
   })
   rawset(self, "tags", tags)
end

function M:lastUpdated()
   return os.date("%c", vim.fn.getftime(tostring(self.dir / "feeds.lua")))
end

---@param id string | string[]
---@param tag string
function M:tag(id, tag)
   local function tag_one(t)
      self.tags[t][id] = true
   end
   if type(tag) == "string" then
      if tag:find(",") then
         for t in ut.split(tag, ",") do
            tag_one(t)
         end
      else
         tag_one(tag)
      end
   elseif type(tag) == "table" then
      for _, v in ipairs(tag) do
         tag_one(v)
      end
   end
   self:save_tags()
end

---@param id string | string[]
---@param tag string
function M:untag(id, tag)
   local function untag_one(t)
      self.tags[t][id] = nil
   end
   if type(tag) == "string" then
      if tag:find(",") then
         for t in ut.split(tag, ",") do
            untag_one(t)
         end
      else
         untag_one(tag)
      end
   elseif type(tag) == "table" then
      for _, v in ipairs(tag) do
         untag_one(v)
      end
   end
   self:save_tags()
end

function M:sort()
   table.sort(self.index, function(a, b)
      return a[2] > b[2]
   end)
end

---@param id string
function M:rm(id)
   for i, v in ipairs(self.index) do
      if v[1] == id then
         table.remove(self.index, i)
      end
   end
   for tag, t in pairs(self.tags) do
      if t[id] then
         self:untag(id, tag)
      end
   end
   self:save_feeds()
   self:save_index()
   pcall(Path.rm, self.dir / "data" / id)
   pcall(Path.rm, self.dir / "object" / id)
   rawset(self, id, nil)
   rawset(mem, id, nil)
end

---@param sort boolean?
---@return Iter
function M:iter(sort)
   if sort then
      self:sort()
   end
   return vim.iter(self.index):map(function(v)
      local id = v[1]
      return id, self[id]
   end)
end

---return a list of db ids base on query
---@param str string
---@return string[]
function M:filter(str)
   if str == "" then
      return {}
   end
   self:update()
   local q = query.parse_query(str)
   local iter

   if q.must_have then
      local ids = {}
      for _, must in ipairs(q.must_have) do
         for k, t in pairs(self.tags) do
            if must == k then
               vim.list_extend(ids, vim.tbl_keys(t))
            end
         end
      end
      iter = vim.iter(ids):map(function(id)
         return id
      end)
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
      iter:find(function(id, time)
         if not time then
            time = self[id].time
         end
         return time <= q.before
      end)
   end

   if q.after then
      iter:filter(function(id, time)
         if not time then
            time = self[id].time
         end
         return time >= q.after
      end)
   end

   if q.must_not_have then
      iter = iter:filter(function(id)
         for _, tag in ipairs(q.must_not_have) do
            if self.tags[tag] and self.tags[tag][id] then
               return false
            end
         end
         return true
      end)
   end

   if q.re then
      iter = iter:filter(function(id)
         local entry = self[id]
         if not entry or not entry.title then
            return false
         end
         for _, reg in ipairs(q.re) do
            if reg:match_str(entry.title) or reg:match_str(entry.link) then
               return true
            end
         end
         return false
      end)
   end

   if q.not_re then
      iter = iter:filter(function(id)
         local entry = self[id]
         if not entry or not entry.title then
            return false
         end
         for _, reg in ipairs(q.not_re) do
            if reg:match_str(entry.title) or reg:match_str(entry.link) then
               return false
            end
         end
         return true
      end)
   end

   if q.feed then
      iter = iter:filter(function(id)
         local url = self[id].feed
         local feed_name = self.feeds[url] and self.feeds[url].title
         if q.feed:match_str(url) or (feed_name and q.feed:match_str(feed_name)) then
            return true
         end
         return false
      end)
   end

   if q.not_feed then
      iter = iter:filter(function(id)
         local url = self[id].feed
         local feed_name = self.feeds[url] and self.feeds[url].title
         if q.not_feed:match_str(url) or (feed_name and q.not_feed:match_str(feed_name)) then
            return false
         end
         return true
      end)
   end

   local ret = iter:fold({}, function(acc, id)
      if not mem[id] then
         mem[id] = Path.load(self.dir / "object" / id)
      end
      acc[#acc + 1] = id
      return acc
   end)

   if q.must_have then
      table.sort(ret, function(a, b)
         return self[a].time > self[b].time
      end)
   end

   return ret
end

function M:save_feeds()
   return Path.save(self.dir / "feeds.lua", self.feeds)
end

function M:save_tags()
   local tags = vim.deepcopy(self.tags)
   setmetatable(tags, nil)
   return Path.save(self.dir / "tags.lua", tags)
end

function M:save_index()
   local buf = {}
   for i, v in ipairs(self.index) do
      buf[i] = tostring(v[2]) .. " " .. v[1]
   end
   Path.save(self.dir / "index", table.concat(buf, "\n"))
end

function M:blowup()
   Path.rm(self.dir)
end

return M.new()
