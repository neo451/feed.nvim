local Path = require "pathlib"
local config = require "feed.config"
local query = require "feed.db.query"
local ut = require "feed.utils"

---@class feed.db
---@field dir string
---@field feeds feed.opml
---@field index table
---@field tags table<string, table<string, boolean>>
---@field is_stored fun(db: feed.db, id: integer): boolean
---@field add fun(db: feed.db, entry: feed.entry, tags: string[]?)
---@field rm fun(db: feed.db, id: integer)
---@field iter Iter
---@field filter fun(db: feed.db, query: string) : string[]
---@field save_entry fun(db: feed.db, id: string): boolean
---@field save_feeds fun(db: feed.db): boolean
---@field tag fun(db: feed.db, id: string, tag: string)
---@field untag fun(db: feed.db, id: string, tag: string)
---@field blowup fun(db: feed.db)

local db_mt = { __class = "feed.db" }

local db_dir = Path.new(config.db_dir)

local data_dir = db_dir / "data"

local object_dir = db_dir / "object"
local feeds_fp = db_dir / "feeds.lua"
local tags_fp = db_dir / "tags.lua"
local index_fp = db_dir / "index"

local pdofile = ut.pdofile
local save_file = ut.save_file
local save_obj = function(fp, object)
   save_file(fp, "return " .. vim.inspect(object))
end
local remove_file = function(fp)
   if vim.fs.rm then
      vim.fs.rm(tostring(fp), { recursive = true })
   else
      vim.fn.delete(tostring(fp), "rf")
   end
end

---@param id string
---@param obj? table
local save_entry = function(id, obj)
   save_obj(object_dir / id, obj)
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

local mem = {}
---@return feed.db
function db_mt.new()
   ensure_path(db_dir, "dir")
   ensure_path(data_dir, "dir")
   ensure_path(object_dir, "dir")
   ensure_path(feeds_fp, "obj")
   ensure_path(tags_fp, "obj")
   ensure_path(index_fp, "file")

   return setmetatable({
      dir = db_dir,
      mem = mem,
   }, db_mt)
end

local function if_path(k)
   return vim.fs.find({ k }, { path = tostring(db_dir) .. "/object/", type = "file" })[1] -- TODO: remove
end

---@param k any
---@return function | feed.entry | string
function db_mt:__index(k)
   if rawget(db_mt, k) then
      return db_mt[k]
   elseif k == "feeds" then
      if not rawget(self, k) then
         local feeds = pdofile(feeds_fp)
         rawset(self, "feeds", feeds)
      end
      return rawget(self, "feeds")
   elseif k == "index" then
      if not rawget(self, k) then
         local index = parse_index()
         rawset(self, "index", index)
      end
      return rawget(self, "index")
   elseif k == "tags" then
      if not rawget(self, k) then
         local tags = pdofile(tags_fp)
         rawset(self, "tags", tags)
      end
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

---@param entry feed.entry
---@param tags string[]?
function db_mt:add(entry, tags)
   if if_path(entry.id) then
      return
   end
   local content = entry.content
   entry.content = nil
   local id = entry.id
   entry.id = nil
   table.insert(self.index, { id, entry.time })
   append_time_id(entry.time, id)
   save_file(data_dir / id, content)
   save_obj(object_dir / id, entry)
   if tags then
      for _, tag in ipairs(tags) do
         self:tag(id, tag)
      end
   end
end

---@param id string
---@param tag string
function db_mt:tag(id, tag)
   if not self[id].tags then
      self[id].tags = {}
   end
   if not self.tags[tag] then
      self.tags[tag] = {}
   end
   self[id].tags[tag] = true
   self.tags[tag][id] = true
   save_entry(id, self[id])
   save_obj(tags_fp, self.tags)
end

---@param id string
---@param tag string
function db_mt:untag(id, tag)
   if not self[id].tags then
      self[id].tags = {}
   end
   if not self.tags[tag] then
      self.tags[tag] = {}
   end
   self[id].tags[tag] = nil
   self.tags[tag][id] = nil
   save_entry(id, self[id])
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
   remove_file(data_dir / id)
   remove_file(object_dir / id)
end

---@param sort any
---@return Iter
function db_mt:iter(sort)
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
function db_mt:filter(str)
   local q = query.parse_query(str)
   local iter

   if q.must_have then
      local must_have = q.must_have[1]
      -- local reg = search.build_regex(must_have)
      local ids = {}
      for k, t in pairs(self.tags) do
         -- if reg:match_str(k) then
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
            -- local r, rev = build_regex(reg)
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
         if not q.feed:match_str(self[id].feed) then
            return false
         end
         return true
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
function db_mt:save_feeds()
   return save_file(feeds_fp, "return " .. vim.inspect(self.feeds))
end

function db_mt:blowup()
   remove_file(db_dir)
end

return db_mt.new()
