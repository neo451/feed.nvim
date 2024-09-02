local lpeg = vim.lpeg
local json = require "rss.json"

local M = {}

---TODO: entities
---TODO: proper naming to spec

lpeg.locale(lpeg)
local P = lpeg.P
local V = lpeg.V
local S = lpeg.S
local Ct = lpeg.Ct
local C = lpeg.C
local alnum = lpeg.alnum
local punct = lpeg.punct

local function parse_start_tag(T, ...)
   local tab = { ... }
   if #tab == 0 then
      return T
   end
   local t = {}
   t[T] = {}
   for i = 1, #tab, 2 do
      local k, v = select(i, ...)
      t[T][k] = v
   end
   return t
end

local function parse_document(...)
   if select("#", ...) == 1 then
      return ...
   end
   local tab = { ... }
   for i, t in ipairs(tab) do
      if vim.tbl_isempty(t) then
         table.remove(tab, i)
      end
   end
   return tab
end

local function parse_content(...)
   if select("#", ...) == 1 then
      return ...
   end
   local acc = {}
   local last_key = nil
   local as_array = nil
   for _, v in pairs { ... } do
      if type(v) == "string" then
         table.insert(acc, v)
         as_array = true
      else
         local key = vim.tbl_keys(v)[1]
         if key == last_key then
            if type(acc[key]) ~= "table" then
               acc[key] = { acc[key] }
            end
            for _, val in pairs(v) do
               table.insert(acc[key], val)
            end
         elseif as_array then
            table.insert(acc, v)
         else
            acc = vim.tbl_deep_extend("keep", acc, v)
         end
         last_key = key
      end
   end
   return acc
end

local function parse_element(T, ele_or_text, _)
   if type(T) == "table" then
      if type(ele_or_text) == "table" then
         -- return { [T] = ele_or_text }
         return vim.tbl_extend("keep", T, ele_or_text)
      else
         if ele_or_text ~= "" then
            local _, v = next(T)
            table.insert(v, ele_or_text)
         end
         return T
      end
   end
   return { [T] = ele_or_text }
end

local text = C((1 - P "<") ^ 1)
local ws = S " \t\n\r" ^ 0

local name = C((alnum - punct + ":") ^ 1) -- TODO: check spec
local quoted_string = P '"' * C((1 - P '"') ^ 0) * P '"'
local kv = ws * name * "=" * quoted_string * ws

local end_tag = P "</" * name * P ">"
local comment = "<!--" * (1 - P "-") ^ 0 * "-->"

local start_tag = P "<" * ws * name * kv ^ 0 * P ">" / parse_start_tag
local just_tag = P "<" * ws * name * kv ^ 0 * P "/>" / parse_start_tag

local CData = C((1 - P "]]>") ^ 0)
local CDSect = "<![CDATA[" * CData * "]]>"
local XMLDecl = P "<?" * name * kv ^ 1 * P "?>" / parse_start_tag --HACK:

local element = V "element"
local content = V "content"
local grammar = {
   [1] = "document",
   document = ws * XMLDecl ^ -1 * ws * element ^ 1 * ws / parse_document,
   content = ws * (text + CDSect + element) ^ 0 * ws / parse_content,
   element = ws * (comment + (start_tag * content * end_tag) + just_tag) / parse_element * ws,
}

---genric markup parseing
---@param src string
---@return table
local function generic_parse(src)
   local rules = Ct(C(grammar))
   local res = rules:match(src)
   if not res then
      return { "failed to parse" }
   else
      return res[2]
   end
end

---check if json
---@param str string
---@return boolean
local function is_json(str)
   local ok = pcall(vim.json.decode, str)
   return ok
end

---@alias rss.feed_type "rss" | "atom" | "json" | "opml"

---@class rss.parse.opts
---@field type rss.feed_type

---parse feed fetch from source
---@param src string
---@param opts rss.parse.opts
---@return table
---@return rss.feed_type
function M.parse(src, opts)
   opts = vim.F.if_nil(opts, {})
   if opts.type == "json" or is_json(src) then
      return vim.json.decode(src), "json"
   elseif opts.type == "opml" then
      local path = vim.fn.expand(src)
      local str = table.concat(vim.fn.readfile(path))
      return generic_parse(str), "opml"
   end
   return generic_parse(src), "rss" -- TODO: check atom or rss??
end

return M
