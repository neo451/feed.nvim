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
         log.warn("curl error for", name)
         -- TODO: parse curl err message, see if connection is rejected or the site has bad response and is simply unavilable
         return err
      end),
   }
   curl.get(job)
end)
M.fetch_co = fetch_co

---fetch xml from source and load them into db
---@param feed table
---@param total integer
function M.update_feed(feed, total)
   local url, name, tags, lastLast
   if type(feed) == "table" then
      url, name, tags = unpack(feed, 1, 3)
   elseif type(feed) == "string" then
      url = feed
   end
   if db.feeds[url] then
      lastLast = db.feeds[url].lastBuild
   end
   local res = fetch_co(url, name)
   if is_valid(res) then
      local ok, ast, f_type, lastBuild = pcall(feedparser.parse, res.body, url, lastLast)
      if ok and ast then
         for _, entry in ipairs(ast.entries) do
            if tags then
               for _, v in ipairs(tags) do
                  entry.tags[v] = true
               end
            end
            db:add(entry)
         end
         db.feeds:append { xmlUrl = url, htmlUrl = ast.link, title = name or ast.title, text = ast.desc, type = f_type, tags = tags, lastBuild = lastBuild }
         db:save()
      else
         log.info("feedparser err for", name)
      end
   else
      log.info("server invalid response err for", name)
   end
   notify.advance(total or 1, name)
end

local cc = 1
local c = 1
local function batch_update_feed(feeds, size)
   for i = c, c + size - 1 do
      local v = feeds[i]
      if not v then
         break
      end
      coroutine.wrap(function()
         M.update_feed(v, #feeds)
         print(("[%d/%d]"):format(cc, #feeds))
         cc = cc + 1
      end)()
   end
   c = c + size
   if c < #feeds then
      vim.defer_fn(function()
         batch_update_feed(feeds, size)
      end, 5000)
   else
      db:save()
      c = 1
   end
end

M.batch_update_feed = batch_update_feed

return M
