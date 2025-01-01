local Coop = require "coop"
local Feedparser = require "feed.parser"
local Curl = require "feed.curl"
local Config = require "feed.config"
local Markdown = require "feed.ui.markdown"
local db = require "feed.db"
local ut = require "feed.utils"
local feeds = db.feeds
local M = {}
local as_completed = require("coop.control").as_completed

local valid_response = ut.list2lookup { 200, 301, 302, 303, 304, 307, 308 }
local encoding_blacklist = ut.list2lookup { "gb2312" }

--- process feed fetch from source
---@param url string
---@param opts? { etag?: string, last_modified?: string, timeout?: integer }
---@return feed.feed | vim.SystemCompleted | { href: string, status: integer, encoding: string }
local function parse_co(url, opts)
   opts = opts or {}
   local response = Curl.get_co(url, opts)
   if response and response.stdout ~= "" and valid_response[response.status] then
      local d = Feedparser.parse(response.stdout, url)
      if d then
         return vim.tbl_extend("keep", response, d)
      end
   end
   return response
end

---@param url string
---@param opts { force: boolean }
function M.update_feed_co(url, opts)
   local tags, last_modified, etag
   if feeds[url] and not opts.force then
      last_modified = feeds[url].last_modified
      etag = feeds[url].etag
   end

   local d = parse_co(url, { last_modified = last_modified, etag = etag, timeout = 10, cmds = Config.curl_params })
   if d then
      if d.status == 301 or d.status == 308 then
         feeds[url] = false
         url = d.href
      elseif not valid_response[d.status] or encoding_blacklist[d.encoding] then
         feeds[url] = false
         return false
      end

      if d.entries then
         for _, entry in ipairs(d.entries) do
            local content = entry.content
            entry.content = nil
            local id = vim.fn.sha256(entry.link)
            Markdown.convert {
               src = content,
               cb = function() end,
               fp = tostring(db.dir / "data" / id),
            }
            db[id] = entry
            if tags then
               db:tag(id, tags)
            end
         end
      end

      feeds[url] = feeds[url] or {}
      local feed = feeds[url]

      feed.htmlUrl = feed.htmlUrl or d.htmlUrl
      feed.title = feed.title or d.title
      feed.description = feed.description or d.description
      feed.version = feed.version or d.version

      feed.last_modified = d.last_modified
      feed.etag = d.etag
      db:save_feeds()
      return true
   else
      return false
   end
end

---@return boolean
local function is_headless()
   return vim.tbl_isempty(vim.api.nvim_list_uis())
end

function M.update_all()
   local jobs, c = 0, 0
   local list = ut.feedlist(feeds, false)

   local tasks = {}

   for i = 1, #list do
      tasks[#tasks + 1] = Coop.spawn(function()
         jobs = jobs + 1
         local url = list[i]
         local ok = M.update_feed_co(url, {})
         local name = ut.url2name(url, feeds)
         return ok, name
      end)
   end

   Coop.spawn(function()
      for t in as_completed(tasks) do
         local ok, name = t()
         c = c + 1
         jobs = jobs - 1
         io.write(table.concat(
            vim.tbl_flatten { (is_headless() and { jobs, c, "/", #list }), name, (ok and "success" or "failed"), "\n" },
            " "))
      end
      os.exit()
   end)
end

return M
