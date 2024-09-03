local lpeg = vim.lpeg

local M = {}

---TODO: entities
---TODO: proper naming to spec

lpeg.locale(lpeg)
local P = lpeg.P
local V = lpeg.V
local S = lpeg.S
local C = lpeg.C
local alnum = lpeg.alnum

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
   return { ... }
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
local ws = S " \t\n\r\f\v"
local ws0 = ws ^ 0
local ws1 = ws ^ 1

local name = (alnum + ":") ^ 1 -- TODO: check spec
local q, sq = P '"', P "'"

local qvalue = (q * C((1 - q) ^ 0) * q) + (sq * C((1 - sq) ^ 0) * sq)
local kv = ws0 * C(name) * "=" * qvalue * ws0

local _qvalue = (q * (1 - q) ^ 0 * q) + (sq * (1 - sq) ^ 0 * sq)
local _kv = ws0 * name * "=" * _qvalue * ws0

local tagStart, tagEnd = P "<", P ">"
local singleTagEnd, pairTagEnd = P "/>", P "</"

local xmlDefStart, xmlDefEnd = P "<?", P "?>"
local XMLDecl = xmlDefStart * name * ws1 * _kv ^ 1 * xmlDefEnd

local commentStart, commentEnd = P "<!--", P "-->"
local comment = commentStart * (1 - commentEnd) ^ 0 * commentEnd

local CDATAStart, CDATAEnd = P "<![CDATA[", P "]]>"
local CData = C((1 - CDATAEnd) ^ 0)
local CDSect = CDATAStart * CData * CDATAEnd

local end_tag = pairTagEnd * name * tagEnd

local start_tag = tagStart * ws0 * C(name) * kv ^ 0 * tagEnd / parse_start_tag
local just_tag = tagStart * ws0 * C(name) * kv ^ 0 * singleTagEnd / parse_start_tag

local BOM = (P "\xEF\xBB\xBF") ^ -1

local element = V "element"
local content = V "content"
local tags = V "tags"
local xml = V "xml"
local html = V "html"

local doctypeName = P "doctype" + P "DOCTYPE"
local doctype = P "<!" * doctypeName * ws1 * kv ^ 1 * ws0 * P ">"

local grammar = P {
   [1] = "ml",
   ml = BOM * ws0 * (xml + html) * ws0,
   tags = ws0 * element ^ 1 * ws0 / parse_document,
   xml = XMLDecl * ws0 * html,
   html = doctype ^ -1 * tags,
   -- document = ws0 * XMLDecl ^ -1 * ws0 * element ^ 1 * ws0 / parse_document,
   content = ws0 * (text + CDSect + element) ^ 0 * ws0 / parse_content,
   element = ws0 * (comment + (start_tag * content * end_tag) + just_tag) / parse_element * ws0,
}

---strip comments for a simpler tree
---@param str string
local function stripComments(str)
   str, _ = string.gsub(str, "<!--.-->", "")
   return str
end

---genric markup parseing
---@param src string
---@return table
local function generic_parse(src)
   src = stripComments(src)
   local res = grammar:match(src)
   if not res then
      return { "failed to parse" }
   else
      return res
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
---@param opts? {type : rss.feed_type, converter : "md" | "org" | "norg" }
---@return table
---@return rss.feed_type
function M.parse(src, opts)
   opts = opts or {}
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
