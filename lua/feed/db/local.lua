local Path = require("feed.db.path")
local config = require("feed.config")
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
---@field last_updated fun(db: feed.db): string
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
   dir = Path.new(dir)
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
---@return function | feed.entry | nil
function M:__index(k)
   if not k then
      return
   end
   local ms = rawget(M, k)
   if ms then
      return ms
   else
      local r = mem[k]
      if not r then
         r = Path.load(self.dir / "object" / k)
         mem[k] = r
      end
      return r
   end
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

---returns the content of entry
---@return string
function M:get(id)
   return ut.read_file(tostring(self.dir / "data" / id))
end

function M:update()
   rawset(self, "feeds", Path.load(self.dir / "feeds.lua"))
   rawset(self, "index", load_index(self.dir / "index"))
   local tags = Path.load(self.dir / "tags.lua")
   setmetatable(tags, {
      __index = function(t, tag)
         rawset(t, tag, {})
         return rawget(t, tag)
      end,
   })
   rawset(self, "tags", tags)
end

function M:last_updated()
   local date_str = os.date("%c", vim.fn.getftime(tostring(self.dir / "feeds.lua")))
   ---@cast date_str -osdate
   return date_str
end

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

function M:get_tags(id)
   local ret = {}
   -- 1. auto tag no [read] as [unread]
   if not (self.tags.read and self.tags.read[id]) then
      ret = { "unread" }
   end

   -- 2. get tags from tags.lua
   for tag, tagees in pairs(self.tags) do
      if tagees[id] then
         ret[#ret + 1] = tag
      end
   end

   return ret
end

function M:sort()
   table.sort(self.index, function(a, b)
      if config.search.sort_order == "ascending" then
         return a[2] < b[2]
      else
         return a[2] > b[2]
      end
   end)
end

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
   Path.rm(self.dir / "data" / id)
   Path.rm(self.dir / "object" / id)
   rawset(self, id, nil)
   rawset(mem, id, nil)
end

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
function M:filter(str)
   str = str or config.search.default_query
   if str == "" then
      return {}
   end
   self:update()
   local q = query.parse_query(str)
   local iter

   if q.must_have then
      local acc = vim.deepcopy(self.tags[q.must_have[1]])
      if not acc then
         return {}
      end
      for _, must in ipairs(q.must_have) do
         if self.tags[must] then
            for k, _ in pairs(acc) do
               if not self.tags[must][k] then
                  acc[k] = nil
               end
            end
         end
      end
      iter = vim.iter(vim.tbl_keys(acc)):map(function(id)
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
         if not entry then
            return false
         end
         for _, reg in ipairs(q.re) do
            if entry.title and reg:match_str(entry.title) then
               return true
            elseif entry.link and reg:match_str(entry.link) then
               return true
            end
         end
         return false
      end)
   end

   if q.not_re then
      iter = iter:filter(function(id)
         local entry = self[id]
         if not entry then
            return false
         end
         for _, reg in ipairs(q.not_re) do
            if entry.title and reg:match_str(entry.title) then
               return false
            elseif entry.link and reg:match_str(entry.link) then
               return false
            end
         end
         return true
      end)
   end

   if q.feed then
      iter = iter:filter(function(id)
         local feed_url = self[id].feed
         local feed_name = self.feeds[feed_url] and self.feeds[feed_url].title
         if q.feed:match_str(feed_url) or (feed_name and q.feed:match_str(feed_name)) then
            return true
         else
            return false
         end
      end)
   end

   if q.not_feed then
      iter = iter:filter(function(id)
         local feed_url = self[id].feed
         local feed_name = self.feeds[feed_url] and self.feeds[feed_url].title
         if q.not_feed:match_str(feed_url) or (feed_name and q.not_feed:match_str(feed_name)) then
            return false
         else
            return true
         end
      end)
   end

   local ret = iter:fold({}, function(acc, id)
      acc[#acc + 1] = id
      return acc
   end)

   if q.must_have then
      table.sort(ret, function(a, b)
         if config.search.sort_order == "ascending" then
            return self[a].time < self[b].time
         else
            return self[a].time > self[b].time
         end
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

---adds missing feed from config to db, rename and tag everything
function M:setup_sync(c_feeds)
   local feeds = self.feeds

   local function process_entries(entries, parent_tags)
      for key, value in pairs(entries) do
         if type(key) == "number" then
            local url = type(value) == "table" and value[1] or value
            local title = type(value) == "table" and value.name or nil
            local entry_tags = type(value) == "table" and value.tags or {}

            local merged_tags = {}
            for _, t in ipairs(parent_tags) do
               merged_tags[t] = true
            end
            for _, t in ipairs(entry_tags) do
               merged_tags[t] = true
            end
            merged_tags = vim.tbl_keys(merged_tags)
            table.sort(merged_tags)

            if not feeds[url] then
               feeds[url] = {}
            end

            feeds[url].title = title or feeds[url].title

            local existing_tags = {}
            if feeds[url].tags then
               for _, t in ipairs(feeds[url].tags) do
                  existing_tags[t] = true
               end
            end

            local new_tags = {}
            for _, t in ipairs(merged_tags) do
               if not existing_tags[t] then
                  table.insert(new_tags, t)
               end
            end

            if #new_tags > 0 then
               feeds[url].tags = feeds[url].tags or {}

               vim.list_extend(feeds[url].tags, new_tags)
               table.sort(feeds[url].tags)
               for id, entry in self:iter() do
                  if entry.feed == url then
                     self:tag(id, new_tags)
                  end
               end
            end
         else
            local tag = key
            local new_parent_tags = {}
            for _, t in ipairs(parent_tags) do
               new_parent_tags[t] = true
            end
            new_parent_tags[tag] = true
            new_parent_tags = vim.tbl_keys(new_parent_tags)
            table.sort(new_parent_tags)
            process_entries(value, new_parent_tags)
         end
      end
   end

   process_entries(c_feeds, {})

   self:save_feeds()
end

---find any unlisted feed in the db
---@return table<string, boolean>
local function find_unlisted_feeds(self)
   local config_urls = {}
   local ret = {}

   for _, v in ipairs(config.feeds) do
      local url = type(v) == "table" and v[1] or v
      config_urls[url] = true
   end

   for url in pairs(self.feeds) do
      if not config_urls[url] then
         ret[url] = true
      end
   end

   for _, entry in self:iter() do
      local feedurl = entry.feed
      if feedurl and not config_urls[feedurl] then
         ret[feedurl] = true
      end
   end

   return ret
end

---Treat config's feeds as the source of truth
---removes any unlisted feed but not the entries
function M:soft_sync()
   local unlisted = find_unlisted_feeds(self)

   for url in pairs(unlisted) do
      self.feeds[url] = nil
   end
   self:save_feeds()
end

---Treat config's feeds as the source of truth
---removes any unlisted feed and all the entries
function M:hard_sync()
   local unlisted = find_unlisted_feeds(self)
   self:soft_sync()

   for id, entry in self:iter() do
      if unlisted[entry.feed] then
         self:rm(id)
      end
   end
end

function M:blowup()
   Path.rm(self.dir)
end

return M
