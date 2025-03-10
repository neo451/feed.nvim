---https://tt-rss.org/ApiReference/
---@diagnostic disable: inject-field
---@class ttrss.feed
---@field cat_id integer
---@field order_id integer
---@field id integer
---@field feed_url string
---@field has_icon boolean
---@field last_updated integer
---@field title string
---@field unread integer

---@class ttrss.headline
---@field always_display_attachments boolean
---@field author string
---@field comments_count integer
---@field comments_link string
---@field feed_id string
---@field feed_title string
---@field guid string
---@field id integer
---@field is_updated boolean
---@field labels string[]
---@field lang string
---@field link string
---@field marked boolean
---@field note string? ????
---@field published boolean
---@field score integer
---@field site_url string
---@field tags string[]
---@field title string
---@field unread boolean
---@field updated integer

---@class ttrss.article
---@field attachments table -- TODO:
---@field author string
---@field comments string
---@field content string
---@field feed_id integer
---@field feed_title string
---@field gui string -- ??? json obj
---@field id integer
---@field labels string[] -- ?
---@field lang string
---@field link string
---@field marked boolean
---@field note nil??
---@field published boolean
---@field score integer
---@field title string
---@field unread boolean
---@field updated integer

---@class ttrss.headlineParams
---@field feed_id? integer | string only output articles for this feed (supports string values to retrieve tag virtual feeds since API level 18, otherwise integer)
---@field limit? integer limits the amount of returned articles (see below)
---@field skip? integer skip this amount of feeds first
---@field filter? string unused
---@field is_cat? boolean - requested feed_id is a category
---@field show_excerpt? boolean - include article excerpt in the output
---@field show_content? boolean - include full article text in the output
---@field view_mode? string = all_articles, unread, adaptive, marked, updated)
---@field include_attachments? boolean - include article attachments (e.g. enclosures) requires version:1.5.3
---@field since_id? integer - only return articles with id greater than since_id requires version:1.5.6
---@field include_nested? boolean - include articles from child categories requires version:1.6.0
---@field order_by? string - override default sort order requires version:1.7.6
---@field sanitize? boolean - sanitize content or not requires version:1.8 (default: true)
---@field force_update? boolean - try to update feed before showing headlines requires version:1.14 (api 9) (default: false)
---@field has_sandbox? boolean - indicate support for sandboxing of iframe elements (default: false)
---@field include_header? boolean - adds status information when returning headlines, instead of array(articles) return value changes to array(header, array(articles)) (api 12)
---Limit:
--
-- Before API level 6 maximum amount of returned headlines is capped at 60, API 6 and above sets it to 200.
--
-- This parameters might change in the future (supported since API level 2):
--
-- search (string) - search query (e.g. a list of keywords)
-- search_mode (string) - all_feeds, this_feed (default), this_cat (category containing requested feed)
-- match_on (string) - ignored
-- Special feed IDs are as follows:
--
-- -1 starred
-- -2 published
-- -3 fresh
-- -4 all articles
-- 0 - archived
-- IDs \< -10 labels
-- Sort order values:
--
-- date_reverse - oldest first
-- feed_dates - newest first, goes by feed date
-- (nothing) - default

---@class ttrssApi
---@field getHeadlines fun(self: ttrssApi, param: ttrss.headlineParams): ttrss.headline[]
---@field getFeeds fun(self: ttrssApi, param: { cat_id: integer, unread_only: boolean, limit: integer, offset: integer, inclued_nested: boolean }): ttrss.feed[]
---@field getArticle fun(self: ttrssApi, param: { article_id: string | integer }): ttrss.article[]
---@field getUnread fun(self: ttrssApi): integer
---@field getVersion fun(self: ttrssApi): string
---@field getApiLevel fun(self: ttrssApi): integer
---@field getConfig fun(self: ttrssApi): table
---@field getCounters fun(self: ttrssApi): table
---@field setArticleLabel fun(self: ttrssApi, param: { article_ids: string, label_id: integer, assign: boolean })
---@field updateArticle fun(self: ttrssApi, param: { article_ids: string, mode: integer, field: integer, data: string })
local api = {}
local Curl = require("feed.curl")
local Config = require("feed.config")

api.__index = api

---@param obj vim.SystemCompleted?
local function decode_check(obj, method) --- TODO: assert decode gets the method
   assert(obj, "no response")
   assert(obj.code == 0, "curl err")
   assert(obj.status == 200, "server did not return 200")
   local response = vim.json.decode(obj.stdout)
   return response.content
end

---@return ttrssApi
function api.new()
   return setmetatable({
      sid = api:login({
         user = Config.protocol.ttrss.user,
         password = Config.protocol.ttrss.password,
      }),
   }, api)
end

local methods = {
   login = "session_id",
   logout = true, -- TODO: autocmd to exit on vim exit
   isLoggedIn = "status",
   getUnread = "unread",
   getVersion = "version",
   getApiLevel = "level",
   getFeeds = true,
   getHeadlines = true,
   getArticle = true,
   getLabels = true,
   getConfig = true,
   getCounters = true, -- TODO: no idea what is this...
   updateArticle = { aync = true },
   setArticleLabel = { aync = true },
}

for k, v in pairs(methods) do
   api[k] = function(self, data)
      local url = require("feed.config").protocol.ttrss.url
      data = data or {}
      data.sid = self.sid
      data.op = k
      if type(v) == "string" then
         return decode_check(Curl.get(url, { data = data }), k)[v]
      elseif type(v) == "table" and v.async then
         return Curl.get(url, { data = data }, function(obj)
            return decode_check(obj, k)
         end)
      else
         return decode_check(Curl.get(url, { data = data }), k)
      end
   end
end

-- TODO:
-- ---@param param { feed_url: string, category_id: integer }
-- ---@async
-- function api:subscribeToFeed(param)
--    param = param or {}
--    param.sid = self.sid
--    param.op = "subscribeToFeed"
--    return decode_check(Curl.get(url, param), param.op)
--    -- Curl.get(url, {
--    --    data = param
--    -- }, function(obj)
--    --    dt(obj)
--    --    -- dt(decode_check(obj))
--    --    -- vim.notify("subscribed!") -- TODO: name?
--    -- end)
-- end
--
-- ---@param param { feed_id: integer }
-- ---@async
-- function api:unsubscribeFeed(param)
--    param = param or {}
--    param.sid = self.sid
--    param.op = "unsubscribeFeed"
--    Curl.get_co(url, {
--       data = param
--    })
--    vim.notify("unsubscribed!")
-- end

local TT = {}
TT.__index = TT

local query = require("feed.db.query")

---@return feed.db
function TT.new()
   local ttrss = api.new()
   local feeds = {}
   for _, feed in ipairs(ttrss:getFeeds({})) do
      feeds[feed.id] = {
         id = feed.id,
         url = feed.feed_url,
         title = feed.title,
      }
   end
   -- for _, v in ipairs(ttrss:getLabels()) do
   --    tags[v.caption] = v.id
   -- end
   return setmetatable({
      api = ttrss,
      feeds = feeds,
      tags = vim.defaulttable(),
      last = os.time(),
   }, TT)
end

function TT:last_updated()
   return os.date("%c", self.last)
end

-- FIXME: multi tags +read +star

---@param str string
---@return integer[]
function TT:filter(str)
   local q = query.parse_query(str)
   local headlines = {}

   local tt_query = {
      feed_id = -4, -- all feeds
      search_mode = "all_feeds",
   }
   local buf = {}

   if q.feed then
      for _, feed in ipairs(self.feeds) do
         if q.feed:match_str(feed.title) then
            tt_query.feed_id = feed.id
            tt_query.search_mode = "this_feed"
         end
      end
   elseif q.must_have then
      for _, v in ipairs(q.must_have) do
         if v == "read" then
            buf[#buf + 1] = "unread:false"
         elseif v == "star" then
            buf[#buf + 1] = "star:true"
         else
            buf[#buf + 1] = "label:" .. v
         end
      end
   elseif q.must_not_have then
      for _, v in ipairs(q.must_not_have) do
         if v == "read" then
            buf[#buf + 1] = "unread:true"
         elseif v == "star" then
            buf[#buf + 1] = "star:false"
         else
            buf[#buf + 1] = "label:" .. v
         end
      end
   end
   tt_query.search = table.concat(buf, " ")
   headlines = self.api:getHeadlines(tt_query)

   local ret = {}
   for _, v in ipairs(headlines) do
      ret[#ret + 1] = v.id
      self[v.id] = {
         link = v.link,
         title = v.title,
         time = v.published or v.updated,
         author = v.author,
         feed = v.feed_title,
         tags = {},
         content = function()
            return self.api:getArticle({ article_id = v.id })[1].content
         end,
      }
   end
   return ret
end

function TT:get_tags(id)
   -- TODO: get remote flags??
   return vim.tbl_keys(self.tags[id])
end

function TT:get(id)
   return self.api:getArticle({ article_id = id })[1].content
end

function TT:tag(id, tag)
   self.tags[id][tag] = true
   if tag == "read" then
      self.api:updateArticle({ article_ids = id, field = 2, mode = 0 })
   elseif tag == "unread" then
      self.api:updateArticle({ article_ids = id, field = 2, mode = 1 })
   elseif tag == "star" then
      self.api:updateArticle({ article_ids = id, field = 0, mode = 1 })
   else
      error("no tags other then star, unread, read for now")
   end
end

function TT:untag(id, tag)
   self.tags[id][tag] = nil
   if tag == "star" then
      self.api:updateArticle({ article_ids = id, field = 0, mode = 0 })
   elseif tag == "unread" then
      self.api:updateArticle({ article_ids = id, field = 2, mode = 1 })
   elseif tag == "read" then
      self.api:updateArticle({ article_ids = id, field = 2, mode = 0 })
   else
      error("no tags other then star, unread, read for now")
   end
end

--- TODO:
function TT:save_feeds() end
function TT:update() end
function TT:setup_sync() end
function TT:hard_sync() end
function TT:soft_sync() end

return TT
