local curl = require "plenary.curl"
local feedparser = require "feed.feedparser"
local db = require "feed.db"
local ut = require "feed.utils"
local log = require "feed.log"

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

local function advance_progress(handle, total)
   if handle then
      handle.percentage = handle.percentage + 100 / total
      if handle.percentage == 100 then
         handle:finish()
      end
   end
end

local fetch_co = ut.cb_to_co(function(cb, url, name)
   local is_rsshub = check_rsshub(url)
   curl.get {
      raw = { "--insecure", "-L" },
      url = url,
      -- timeout = 300,
      callback = vim.schedule_wrap(cb),
      query = is_rsshub and { format = "json" } or nil,
      on_error = vim.schedule_wrap(function(err)
         advance_progress()
         log.warn("curl error for", name)
         -- log.warn(err.message, name)
         -- TODO: parse curl err message, see if connection is rejected or the site has bad response and is simply unavilable
         -- print(err.message)
         return err
      end),
   }
end)
M.fetch_co = fetch_co

---@param feed table | string
---@return string?
---@return string?
local function get_feed_info(feed)
   vim.validate {
      feed = { feed, { "table", "string" } },
   }
   if type(feed) == "table" then
      if feed.xmlUrl then
         return feed.xmlUrl, feed.title or feed.text or nil
      elseif feed[1] then
         return feed[1], feed.name or nil
      end
   else
      return feed, nil
   end
end

---fetch xml from source and load them into db
---@param feed feed.feed
function M.update_feed(feed, handle, total)
   local url, name = get_feed_info(feed)
   local res = fetch_co(url, name)
   if is_valid(res) then
      local ok, ast, f_type = pcall(feedparser.parse, res.body)
      if ok then
         for _, entry in ipairs(ast.entries) do
            db:add(entry)
         end
         -- TODO: check if info changed then update feed
         db.feeds:append { xmlUrl = url, htmlUrl = ast.link, title = name or ast.title, text = ast.desc, type = f_type }
         db:save { update_feed = true }
      else
         log.info("feedparser err for", name)
      end
   else
      log.info("server invalid response err for", name)
   end
   if handle and total then
      advance_progress(handle, total)
   else
      vim.notify("feed.nvim: " .. name .. " fetched")
   end
end

local function batch_update_feed(feeds, size, handle)
   local c = 1
   for i = c, c + size - 1 do
      local v = feeds[i]
      if not v then
         break
      end
      coroutine.wrap(function()
         M.update_feed(v, handle, #feeds)
      end)()
   end
   c = c + size
   if c < #feeds then
      vim.defer_fn(function()
         batch_update_feed(feeds, size, handle)
      end, 5000)
   end
end

M.batch_update_feed = batch_update_feed

return M
