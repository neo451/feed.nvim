---@alias xml.ast table<string, string | table>

local F = require "plenary.functional"

local transforms = {
   md = "%s",
   h1 = "# %s",
   h2 = "## %s",
   h3 = "### %s",
   h4 = "#### %s",
   h5 = "##### %s",
   p = "  %s",
   a = "[%s](%s)",
   -- code = [[```%s %s ```]],
   code = "`%s`",
   pre = "",
}
local traverse_hashtable, traverse_array
---@param t table<number, any>
---@return string
function traverse_array(t, is_root)
   local buf = {}
   for _, v in ipairs(t) do
      if type(v) == "string" then
         buf[#buf + 1] = v
      elseif type(v) == "table" then
         if vim.isarray(v) then
            buf[#buf + 1] = traverse_array(v)
         else
            buf[#buf + 1] = traverse_hashtable(v)
         end
      end
   end
   return F.join(buf, is_root and "\n" or "")
end

local function format_code(v)
   if type(v) == "string" then
      return transforms.code:format(v)
   else
      return ("```%s\n%s\n```"):format(v.language, v[1]) -- ?
   end
end

---@param t table<string, any>
---@return string
function traverse_hashtable(t)
   local buf = {}
   for k, v in pairs(t) do
      buf[#buf + 1] = format_code(v)
   end
   return F.join(buf, "")
end

local xml = require "rss.xml"
--
-- local ast = xml.parse [[<code language="zig">const std = @import("std")</code>]]
-- local ast = xml.parse [[<code>const std = @import("std")</code>]]
-- print(traverse_hashtable(ast))

return traverse_array
