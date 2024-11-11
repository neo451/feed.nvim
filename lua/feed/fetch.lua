local feedparser = require "feed.feedparser"
local db = require "feed.db"
local progress = require "feed.progress"
local date = require "feed.date"

local M = {}

local function check_rsshub(_)
   return false -- TODO:
end

local function header_says_html(hdrs)
   for _, v in ipairs(hdrs) do
      local tag = v:lower()
      if tag:find "html" then -- TODO: maybe wrong, more formal
         return true
      end
   end
   return false
end

local function doctype_says_html(body)
   return body:find "<!DOCTYPE html>"
end

-- TODO: right?
---@param res table
---@return boolean
local function is_valid(res)
   if res.status == 404 or header_says_html(res.headers) or doctype_says_html(res.body) then -- TODO: right?
      return false
   end
   return true
end

-- TODO: proxy??

local function readlines(data)
   data = data:gsub("\r", "")
   return vim.split(data, "\n")
end

local function fetch(cb, url, timeout)
   vim.system({
      "curl",
      "-I",
      "-m",
      tostring(timeout),
      url,
      "--next",
      "-m",
      tostring(timeout),
      url,
   }, { text = true }, function(obj)
      local split = vim.split(obj.stdout, "\n\n")
      local header = table.remove(split, 1)
      local headers = readlines(header)
      local status = tonumber(string.match(headers[1], "([%w+]%d+)"))
      ---@diagnostic disable-next-line: inject-field
      obj.status = status
      ---@diagnostic disable-next-line: inject-field
      obj.body = obj.stdout:sub(#header + 3, -1)
      ---@diagnostic disable-next-line: inject-field
      obj.headers = headers
      vim.schedule_wrap(cb)(obj)
   end)
end

M.fetch = fetch

---fetch xml from source and load them into db
---@param feed table
---@param total integer
function M.update_feed(feed, total)
   local url, name, tags, lastUpdated
   if type(feed) == "table" then
      url, name, tags = unpack(feed, 1, 3)
   elseif type(feed) == "string" then
      url = feed
   end
   if db.feeds[url] then
      lastUpdated = db.feeds[url].lastUpdated
   end
   fetch(function(res)
      if is_valid(res) then
         local ok, ret = pcall(feedparser.parse, res.body, url, lastUpdated)
         if ok then
            if ret then -- TODO: assert check_feed
               local ast, feedtype, lastBuild = ret.ast, ret.feedtype, ret.lastBuild
               if ast.entries then
                  for _, entry in ipairs(ast.entries) do
                     if tags then
                        for _, v in ipairs(tags) do
                           entry.tags[v] = true
                        end
                     end
                     db:add(entry)
                  end
               end
               if not db.feeds[url] then
                  db.feeds[url] = {
                     htmlUrl = ast.link,
                     title = ast.title,
                     text = ast.desc,
                     type = feedtype,
                     tags = tags,
                     lastUpdated = lastBuild or tostring(date.today),
                  }
               else
                  db.feeds[url].lastUpdated = lastBuild or tostring(date.today)
               end
               db:save_feeds()
            end
         else
            db:save_err("fp", url, ret)
         end
      else
         if res.code == 28 then
            db:save_err("timeout", url)
         else
            db:save_err("response", url, vim.inspect(res))
         end
      end
      progress.advance(total or 1, name or url)
   end, url, 15)
end

local c = 1
local function batch_update_feed(feeds, size)
   for i = c, c + size - 1 do
      local v = feeds[i]
      if not v then
         break
      end
      M.update_feed(v, #feeds)
   end
   if c < #feeds then
      vim.defer_fn(function()
         batch_update_feed(feeds, size)
      end, 5000)
   else
      c = 1
   end
   c = c + size
end

M.batch_update_feed = batch_update_feed

return M
