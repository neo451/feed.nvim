local xml = require "feed.parser.xml"
local fetch = require "feed.parser.fetch"
local ut = require "feed.utils"

local handle_rss = require "feed.parser.rss"
local handle_atom = require "feed.parser.atom"
local handle_json = require "feed.parser.jsonfeed"

local M = {}

local looks_like_url = ut.looks_like_url

---check if json
---@param str string
---@return boolean
local function is_json(str)
   return pcall(vim.json.decode, str)
end

---Note:
---1. feed
--- 1.1 link/href link to homepage or xml
--- 1.2 title >> link
--- 1.3 desc >> title
--- 1.4 entries >> {}
--- 1.5 version
--- 1.6 type
---2. entry
--- 2.1 link
--- 2.2 feed
--- 2.3 title >> content:sub(0, 20) .. "..."
--- 2.4 author >> feed.title
--- 2.5 time >> lastUpdated >> os.time()
--- 2.6 content >> "" -> resolve links in html

-- FIX: vim.validate
-- TODO: bozo flag

---@class feed.parser_opts
---@field etag? string
---@field last_modified? string #?
---@field curl_params? table<string, string | number> #?
---@field callback? fun(table)

function M.parse_src(src, url)
   src = src:gsub("\n", "")
   if is_json(src) then
      return handle_json(vim.json.decode(src), url)
   else
      local raw_ast = xml.parse(src, url)
      if raw_ast then
         if raw_ast.rss or raw_ast["rdf"] then -- TODO: rdf
            return handle_rss(raw_ast, url)
         elseif raw_ast.feed then
            return handle_atom(raw_ast, url)
         else
            error "unknown feedtype"
         end
      end
   end
end

---parse feed fetch from source
---@param url_or_src string
---@param opts? feed.parser_opts
---@return table | boolean
function M.parse(url_or_src, opts)
   opts = opts or {}
   if looks_like_url(url_or_src) then
      -- if opts.callback then
      --    fetch.fetch(function(obj)
      --       local res = M.parse_src(obj.body, obj.location)
      --       obj = vim.tbl_extend("keep", res, obj)
      --       opts.callback(obj)
      --    end, url_or_src, opts.timeout or 10, opts.etag, opts.last_modified)
      -- else
      -- print(opts.etag)
      local response = fetch.fetch_co(url_or_src, opts) -- TODO:
      local parsed
      if response.body == "" or not response.body then
         parsed = { entries = {} }
      else
         parsed = M.parse_src(response.body, url_or_src)
      end
      return vim.tbl_extend("keep", response, parsed)
      -- return vim.tbl_extend("keep", response, parsed)
      -- end
   else
      return M.parse_src(url_or_src, opts.url) -- url??
   end
   return false
end

-- local url = "https://neovim.io/news.xml"
-- -- local function cb(res)
-- --    print(res.status)
-- --    M.parse(url, { callback = cb, etag = res.etag })
-- --    -- print(res.etag, res.last_modified)
-- --    -- vim.print(#res.entries)
-- -- end
-- -- -- local url = "https://www.gcores.com/rss"
-- -- M.parse(url, { callback = cb, etag = 'W/"67200cc2-27ad5"' })
--
-- coroutine.wrap(function()
--    local d = M.parse(url)
--    local d2 = M.parse(url, { etag = d.etag, last_modified = d.last_modified })
--    print(#d2.entries)
-- end)()

return M
