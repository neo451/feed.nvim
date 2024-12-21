local Feedparser = require "feed.parser"
---@type feed.db
local DB = require "feed.db"
local Config = require "feed.config"
local Markdown = require "feed.ui.markdown"
local Curl = require "feed.curl"
local ut = require "feed.utils"
local url2name = ut.url2name
local Coop = require "coop"
local MpscQueue = require('coop.mpsc-queue').MpscQueue
local q = MpscQueue.new()
local uv_utils = require "coop.uv-utils"


local M = {}
local feeds = DB.feeds

local encoding_blacklist = {
   ["gb2312"] = true,
}

local valid_response = {
   [200] = true,
   [301] = true,
   [302] = true,
   [303] = true,
   [304] = true,
   [307] = true,
   [308] = true,
}

---parse feed fetch from source
---@param url string
---@param opts? { etag?: string, last_modified?: string, timeout?: integer }
---@return table?
function M.parse_co(url, opts)
   opts = opts or {}
   local response = Curl.get_co(url, opts)
   if response then
      if response.stdout ~= "" and valid_response[response.status] then
         local d = Feedparser.parse(response.stdout, url)
         if d then
            return vim.tbl_extend("keep", response, d)
         end
      end
      return response
   end
end

---@param url string
---@param opts { force: boolean }
function M.update_feed_co(url, opts)
   local tags, last_modified, etag
   if feeds[url] and not opts.force then
      last_modified = feeds[url].last_modified
      etag = feeds[url].etag
      tags = vim.deepcopy(feeds[url].tags)
   end
   local d = M.parse_co(url, { timeout = 10, etag = etag, last_modified = last_modified, cmds = Config.curl_params })

   local ok = true
   if d then
      if d.status == 301 then -- permenantly moved
         feeds[url] = d.href  -- to keep config consistent
         url = d.href
      elseif not valid_response[d.status] or encoding_blacklist[d.encoding] then
         feeds[url] = false
         ok = false
      end
      if d.entries and not vim.tbl_isempty(d.entries) then
         for _, entry in ipairs(d.entries) do
            local content = entry.content
            entry.content = nil
            local id = vim.fn.sha256(entry.link)
            Markdown.convert(content, function() end, true, tostring(DB.dir / "data" / id))
            DB[id] = entry
            if tags then
               DB:tag(id, tags)
            end
         end
      end
      feeds[url] = feeds[url] or {}
      -- TODO: tags and htmlUrl can change? --
      feeds[url].htmlUrl = feeds[url].htmlUrl or d.link
      feeds[url].title = feeds[url].title or d.title
      feeds[url].description = feeds[url].description or d.desc
      feeds[url].version = feeds[url].version or d.version
      feeds[url].tags = feeds[url].tags or tags -- TDOO: feed tags -- FIX: compare new tgs
      feeds[url].last_modified = d.last_modified
      feeds[url].etag = d.etag
      DB:save_feeds()
   else
      ok = false
   end
   return ok
end

function M.update_all_co()
   vim.iter(feeds):each(function(k)
      q:push(k)
   end)

   local jobs = 0
   local size = 20
   local c = 0

   Coop.spawn(function()
      while not q:empty() do
         for _ = 1, size do
            if not q:empty() then
               jobs = jobs + 1
               if jobs > size then
                  uv_utils.sleep(1000)
               end
               local url = q:pop()
               M.update_feed(url, {}, function(ok)
                  local name = url2name(url, feeds)
                  c = c + 1
                  jobs = jobs - 1
                  io.write(table.concat(
                     { jobs, c, "/", vim.tbl_count(feeds), name, (ok and "success" or "failed"), "\n" }, " "))
                  if c == vim.tbl_count(feeds) and q:empty() then
                     os.exit()
                  end
               end)
            end
         end
      end
   end)
end

return M
