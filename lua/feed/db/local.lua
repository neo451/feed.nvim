local Path = require "pathlib"
local Config = require "feed.config"
local query = require "feed.db.query"
local ut = require "feed.utils"

---@class feed.db
---@field dir string
---@field feeds feed.opml
---@field index table
---@field tags table<string, table<string, boolean>>
---@field add fun(db: feed.db, entry: feed.entry, tags: string[]?)
---@field rm fun(db: feed.db, id: integer)
---@field iter Iter
---@field filter fun(db: feed.db, query: string) : string[]
---@field save_entry fun(db: feed.db, id: string): boolean
---@field save_feeds fun(db: feed.db): boolean
---@field tag fun(db: feed.db, id: string, tag: string | string[])
---@field untag fun(db: feed.db, id: string, tag: string | string[])
---@field blowup fun(db: feed.db)
---@field update fun(db: feed.db)

local M = {}
M.__index = M

local db_dir = Path.new(Config.db_dir)

local data_dir = db_dir / "data"

local object_dir = db_dir / "object"
local feeds_fp = db_dir / "feeds.lua"
local tags_fp = db_dir / "tags.lua"
local list_fp = db_dir / "list.lua"
local index_fp = db_dir / "index"

local pdofile = ut.pdofile
local save_file = ut.save_file
local save_obj = ut.save_obj
local remove_file = function(fp)
   if vim.fs.rm then
      vim.fs.rm(tostring(fp), { recursive = true })
   else
      vim.fn.delete(tostring(fp), "rf")
   end
end

local permisson = Path.permission "rwxr-xr-x"

---@param fp PathlibPath
---@param type any
local ensure_path = function(fp, type)
   if type == "dir" then
      if not fp:is_dir(true) then
         fp:mkdir(permisson, true)
      end
   elseif type == "obj" then
      if not fp:is_file(true) then
         fp:touch(permisson, true)
         ---@diagnostic disable-next-line: param-type-mismatch
         fp:io_write("return " .. vim.inspect {})
      end
   elseif type == "file" then
      if not fp:is_file(true) then
         fp:touch(permisson, true)
      end
   end
end

local append_time_id = function(time, id)
   index_fp:fs_append(time .. " " .. id .. "\n")
end

local function parse_index()
   local res = {}
   for line in io.lines(tostring(index_fp)) do
      local time, id = line:match "(%d+)%s(%S+)"
      res[#res + 1] = { id, tonumber(time) }
   end
   return res
end

function M:save_index()
   local buf = {}
   for i, v in ipairs(self.index) do
      buf[i] = tostring(v[2]) .. " " .. v[1]
   end
   save_file(index_fp, table.concat(buf, "\n"))
end

local mem = {}

---@return feed.db
function M.new()
   ensure_path(db_dir, "dir")
   ensure_path(data_dir, "dir")
   ensure_path(object_dir, "dir")
   ensure_path(feeds_fp, "obj")
   ensure_path(tags_fp, "obj")
   ensure_path(list_fp, "obj")
   ensure_path(index_fp, "file")

   return setmetatable({
      dir = db_dir
   }, M)
end

local function if_path(k)
   return vim.fs.find({ k }, { path = tostring(db_dir) .. "/object/", type = "file" })[1] -- TODO: remove
end

---@param k any
---@return function | feed.entry | string
function M:__index(k)
   if rawget(M, k) then
      return M[k]
   elseif k == "feeds" then
      local feeds = pdofile(feeds_fp)
      rawset(self, "feeds", feeds)
      return rawget(self, "feeds")
   elseif k == "index" then
      local index = parse_index()
      rawset(self, "index", index)
      return rawget(self, "index")
   elseif k == "tags" then
      local tags = pdofile(tags_fp)
      setmetatable(tags, {
         __index = function(t, tag)
            rawset(t, tag, {})
            return rawget(t, tag)
         end
      })
      rawset(self, "tags", tags)
      return rawget(self, "tags")
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

function M:update()
   local feeds = pdofile(feeds_fp)
   rawset(self, "feeds", feeds)
   local index = parse_index()
   rawset(self, "index", index)
   local tags = pdofile(tags_fp)
   setmetatable(tags, {
      __index = function(t, tag)
         rawset(t, tag, {})
         return rawget(t, tag)
      end
   })
   rawset(self, "tags", tags)
end

function M:lastUpdated()
   return os.date("%c", vim.fn.getftime(tostring(feeds_fp)))
end

---@param id string
---@param entry feed.entry
function M:__newindex(id, entry)
   if not id or if_path(id) then
      return
   end
   table.insert(self.index, { id, entry.time })
   append_time_id(entry.time, id)
   save_obj(object_dir / id, entry)
end

local function split_comma(str)
   return vim.iter(vim.split(str, ",")):fold({}, function(acc, v)
      if vim.trim(v) ~= "" then
         acc[#acc + 1] = vim.trim(v)
      end
      return acc
   end)
end

---@param id string | string[]
---@param tag string
function M:tag(id, tag)
   local function tag_one(t)
      self.tags[t][id] = true
      self:save_feeds()
   end
   if type(tag) == "string" then
      if tag:find(",") then
         for _, v in ipairs(split_comma(tag)) do
            tag_one(v)
         end
      else
         tag_one(tag)
      end
   elseif type(tag) == "table" then
      for _, v in ipairs(tag) do
         tag_one(v)
      end
   end
end

---@param id string | string[]
---@param tag string
function M:untag(id, tag)
   local function tag_one(t)
      self.tags[t][id] = nil
      self:save_feeds()
   end
   if type(tag) == "string" then
      if tag:find(",") then
         for _, v in ipairs(split_comma(tag)) do
            tag_one(v)
         end
      else
         tag_one(tag)
      end
   elseif type(tag) == "table" then
      for _, v in ipairs(tag) do
         tag_one(v)
      end
   end
end

function M:sort()
   table.sort(self.index, function(a, b)
      return a[2] > b[2]
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
   pcall(remove_file, data_dir / id)
   pcall(remove_file, object_dir / id)
   rawset(self, id, nil)
   rawset(mem, id, nil)
end

---@param sort any
---@return Iter
function M:iter(sort)
   if sort then
      self:sort()
   end
   return vim.iter(self.index):map(function(v)
      local id = v[1]
      local r = pdofile(object_dir / id)
      mem[id] = r
      return id, r
   end)
end

---return a list of db ids base on query
---@param str string
---@return string[]
function M:filter(str)
   if str == "" then
      return {}
   end
   local q = query.parse_query(str)
   local iter

   if q.must_have then
      local must_have = q.must_have[1]
      local ids = {}
      for k, t in pairs(self.tags) do
         if must_have == k then
            vim.list_extend(ids, vim.tbl_keys(t))
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
         mem[id] = pdofile(object_dir / id)
         local entry = self[id]
         if not entry or not entry.title then
            return false
         end
         for _, reg in ipairs(q.re) do
            if not reg:match_str(entry.title) then
               return false
            end
         end
         return true
      end)
   end

   if q.feed then
      iter = iter:filter(function(id)
         mem[id] = pdofile(object_dir / id)
         local url = self[id].feed
         local feed_name = self.feeds[url] and self.feeds[url].title
         if q.feed:match_str(url) or (feed_name and q.feed:match_str(feed_name)) then
            return true
         end
         return false
      end)
   end

   local ret = iter:fold({}, function(acc, id)
      if not mem[id] then
         mem[id] = pdofile(object_dir / id)
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

---@return boolean
function M:save_feeds()
   return save_file(feeds_fp, "return " .. vim.inspect(self.feeds, { process = false }))
end

function M:save_feeds()
   local tags = vim.deepcopy(self.tags)
   setmetatable(tags, {})
   return save_file(tags_fp, "return " .. vim.inspect(tags, { process = false }))
end

function M:blowup()
   remove_file(db_dir)
end

return M.new()
