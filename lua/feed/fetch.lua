local Feedparser = require "feed.parser"
---@type feed.db
local db = require "feed.db"
local Config = require "feed.config"
local Markdown = require "feed.ui.markdown"
local Curl = require "feed.curl"

local M = {}
local feeds = db.feeds

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
   [308] = true, -- TODO:
}

---parse feed fetch from source
---@param url string
---@param opts? { etag?: string, last_modified?: string, timeout?: integer }
---@return table?
function M.parse(url, opts, cb)
   local parse = {
      [200] = true,
      [301] = true,
      [302] = true,
      [303] = true,
      [307] = true,
      [308] = true,
   }
   opts = opts or {}
   Curl.get(url, opts, function(response)
      if response then
         if response.stdout ~= "" and parse[response.status] then
            local d = Feedparser.parse(response.stdout, url)
            if d then
               return cb(vim.tbl_extend("keep", response, d))
            end
         end
         return cb(response)
      end
   end)
end

---@param url string
---@param opts { force: boolean }
function M.update_feed(url, opts, cb)
   local tags, last_modified, etag, name
   if feeds[url] and not opts.force then
      last_modified = feeds[url].last_modified
      etag = feeds[url].etag
      tags = vim.deepcopy(feeds[url].tags)
      name = feeds[url].title
   end
   M.parse(url, { timeout = 10, etag = etag, last_modified = last_modified, cmds = Config.curl_params },
      function(d)
         local ok = true
         if d then
            if d.status == 301 then -- permenantly moved
               feeds[url] = d.href  -- to keep config consistent
               url = d.href
            elseif not valid_response[d.status] or encoding_blacklist[d.encoding] then
               feeds[url] = nil -- TODO: set to false
               ok = false
            end
            if d.entries and not vim.tbl_isempty(d.entries) then
               for _, entry in ipairs(d.entries) do
                  local content = entry.content
                  entry.content = nil
                  Markdown.convert(content, vim.schedule_wrap(function(lines)
                     db:add(entry, table.concat(lines, "\n"), tags) -- TODO: name
                  end), true)
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
            db:save_feeds()
         else
            ok = false
         end
         return cb(ok)
      end)
end

function M.update_all()
   local ut = require "feed.utils"
   local Promise = require "feed.lib.promise"
   local list = require("feed.utils").feedlist(feeds)

   local c = 0
   local jobs = 0

   Promise.map(function(url)
      jobs = jobs + 1
      require("feed.fetch").update_feed(url, {}, function(ok)
         local name = ut.url2name(url, feeds)
         c = c + 1
         io.write(table.concat({ name, (ok and "success" or "failed"), "\n" }, " "))
         jobs = jobs - 1

         if c == #list then
            vim.schedule(function()
               os.exit()
            end)
         end
      end)
   end, list, 20)
end

return M
