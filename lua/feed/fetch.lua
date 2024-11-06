local curl = require "plenary.curl"
local feedparser = require "feed.feedparser"
local db = require "feed.db"
local ut = require "feed.utils"
local log = require "feed.log"
local notify = require "feed.notify"

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

-- TODO: proper timeout???
-- TODO: proxy??
local fetch_co = ut.cb_to_co(function(cb, url, name)
   local is_rsshub = check_rsshub(url)
   local job = {
      raw = { "--insecure", "-L" },
      url = url,
      callback = vim.schedule_wrap(cb),
      timeout = 5000,
      query = is_rsshub and { format = "json" } or nil,
      on_error = vim.schedule_wrap(function(err)
         -- advance_progress()
         log.warn("curl error for", name)
         -- log.warn(err.message, name)
         -- TODO: parse curl err message, see if connection is rejected or the site has bad response and is simply unavilable
         -- print(err.message)
         return err
      end),
   }
   pcall(curl.get, job)
   -- if not ok then -- TODO: only retry once
   --    vim.defer_fn(function()
   --       pcall(curl.get, job)
   --    end, 1000)
   -- end
end)
M.fetch_co = fetch_co

---@param feed table | string
---@return string?
---@return string?
---@return string[]?
local function get_feed_info(feed)
   vim.validate {
      feed = { feed, { "table", "string" } },
   }
   if type(feed) == "table" then
      if feed.xmlUrl then
         return feed.xmlUrl, feed.title or feed.text or nil, feed.tags
      elseif feed[1] then
         return feed[1], feed.name or nil, feed.tags
      end
   else
      return feed, nil, nil
   end
end

---fetch xml from source and load them into db
---@param feed feed.feed
function M.update_feed(feed, total)
   local url, name, tags = get_feed_info(feed)
   local res = fetch_co(url, name)
   if is_valid(res) then
      local ok, ast, f_type = pcall(feedparser.parse, res.body)
      if ok then
         for _, entry in ipairs(ast.entries) do
            if tags then
               for _, v in ipairs(tags) do
                  entry.tags[v] = true
               end
            end
            db:add(entry)
         end
         -- TODO: check if info changed then update feed
         db.feeds:append { xmlUrl = url, htmlUrl = ast.link, title = name or ast.title, text = ast.desc, type = f_type, tags = tags }
         db:save()
      else
         log.info("feedparser err for", name)
      end
   else
      log.info("server invalid response err for", name)
   end
   notify.advance(total or 1, name or url)
end

local function batch_update_feed(feeds, size)
   local c = 1
   for i = c, c + size - 1 do
      local v = feeds[i]
      if not v then
         break
      end
      coroutine.wrap(function()
         M.update_feed(v, #feeds)
      end)()
   end
   c = c + size
   if c < #feeds then
      vim.defer_fn(function()
         batch_update_feed(feeds, size)
      end, 5000)
   end
end

local function _batch_update_feed(feeds, _, handle)
   for _, v in ipairs(feeds) do
      coroutine.wrap(function()
         M.update_feed(v, #feeds)
      end)()
   end
end

M.batch_update_feed = _batch_update_feed

return M
