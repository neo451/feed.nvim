local Path = require "plenary.path"
local path_ensured = false
local config = require "feed.config"
local opml = require "feed.opml"

--- TODO: move feeds index here, and store with index

local index_header = { version = "0.1", ids = {} }
local opml_template = [[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>feed_nvim_export</title></head><body>
<outline text="neovim.io" title="neovim.io" type="rss" xmlUrl="https://neovim.io/news.xml" htmlUrl="https://neovim.io/news"/>
</body></opml>]]

---@param dir string
local function prepare_db(dir)
   dir = vim.fs.normalize(config.db_dir)
   local dir_handle = Path:new(dir)
   if not dir_handle:is_dir() then
      dir_handle:mkdir()
   end
   local data_dir_handle = Path:new(dir .. "/data")
   if not dir_handle:is_dir() then
      dir_handle:mkdir()
   end
   if not data_dir_handle:is_dir() then
      data_dir_handle:mkdir()
   end
   local index_path = Path:new(dir .. "/index")
   if not index_path:is_file() then
      index_path:touch()
      index_path:write("return " .. vim.inspect(index_header), "w")
   end
   local opml_path = Path:new(dir .. "/feeds.opml")
   if not opml_path:is_file() then
      opml_path:touch()
      opml_path:write(opml_template, "w")
   end
   path_ensured = true
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

---@param id integer
---@return boolean
function db_mt:is_stored(id)
   return self.index.ids[id]
end

---@param entry feed.entry
function db_mt:add(entry)
   if self:is_stored(entry.id) then
      return
   end
   local content = entry.content
   entry.content = nil
   table.insert(self.index, entry)
   self.index.ids[entry.id] = #self.index
   save_file(self.dir .. "/data/" .. entry.id, content)
end

---@param id string
---@return feed.entry
function db_mt:lookup(id)
   local idx = self.index.ids[id]
   return self.index[idx]
end

---@param entry feed.entry
---@return string
function db_mt:address(entry)
   local data_dir = "/data/"
   return self.dir .. data_dir .. entry.id
end

local function update_index(dir)
   if not path_ensured then
      dir = prepare_db(config.db_dir)
   end
   local ok, res = pcall(dofile, dir .. "/index")
   if ok and res then
      return res
   else
      error("[feed.nvim]: failed to load index: " .. res)
   end
end

function db_mt:update_index()
   self.index = update_index(self.dir)
end

---@param entry feed.entry
---@return string?
function db_mt:get(entry)
   return get_file(self.dir .. "/data/" .. entry.id)
end

---@param index integer
---@return string?
function db_mt:at(index)
   local entry = self.index[index]
   return self:get(entry)
end

function db_mt:save(opts)
   opts = opts or {}
   if opts.update_feed then
      self.feeds:export(self.dir .. "/feeds.opml")
   end
   save_file(self.dir .. "/index", "return " .. vim.inspect(self.index))
end

function db_mt:blowup()
   vim.fn.delete(self.dir, "rf")
   path_ensured = false
end

local dir = prepare_db(config.db_dir)
local index = update_index(dir)
local str = get_file(dir .. "/feeds.opml")
local feeds = opml.import(str)

return setmetatable({
   dir = dir,
   index = index,
   feeds = feeds,
}, db_mt)
