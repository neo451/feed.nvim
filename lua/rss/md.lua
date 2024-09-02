---@alias xml.ast table<string, string | table>

local F = require "plenary.functional"

local transforms = {
   md = "%s",
   -- h1 = "# %s",
   -- h2 = "## %s",
   -- h3 = "### %s",
   h4 = function(v)
      return "#### " .. v[1]
   end,
   h5 = "##### %s",
   p = function(v)
      return ("  %s"):format(v)
   end,
   a = function(v)
      return ("[%s](%s)"):format(v[1], v.href)
   end,
   -- code = [[```%s %s ```]],
   code = "`%s`",
   pre = "",
}
local traverse_hashtable, traverse_array
---@param t table<number, any>
---@return string
function traverse_array(t, is_root)
   for i, v in ipairs(t) do
      if type(v) == "string" then
      elseif type(v) == "table" then
         if vim.isarray(v) then
            t[i] = traverse_array(v, false)
         else
            -- pp(v)
            t[i] = traverse_hashtable(v)
         end
      end
   end
   return t
   -- return F.join(t, is_root and "\n" or "")

   -- return F.join(buf, is_root and "\n" or "")
end

local function format_code(v)
   if type(v) == "string" then
      return transforms.code:format(v)
   else
      return ("```%s\n%s\n```"):format(v.language, v[1]) -- ?
   end
end

--- TODO: parser still wrong, not parellel, order wrong
---
-- {
--    p = {
--       "So we developed JSON Feed, a format similar to ",
--       {
--          a = {
--             "RSS",
--             href = "http://cyber.harvard.edu/rss/rss.html",
--          },
--       },
--       "and ",
--       "but in JSON. It reflects the lessons learned from our years of work reading and publishing feeds.",
--       a = { {
--          "Atom",
--          href = "https://tools.ietf.org/html/rfc4287",
--       } },
--    },

---@param t table<string, any>
---@return string
function traverse_hashtable(t)
   -- local buf = {}
   for k, v in pairs(t) do
      if vim.isarray(v) then
         -- print(k, v)
         t[k] = traverse_array(v, false)
      else
         print(k, v)
         if k == "code" then
            -- buf[#buf + 1] = format_code(v)
            t[k] = format_code(v)
         else
            t[k] = transforms[k](v)
         end
      end
   end
   return t
   -- return F.join(t, "")
end

--- TODO: use html_lpeg.lua!!
local xml = require "rss.xml"

local to_walk = loadfile "/home/n451/Plugins/rss.nvim/data/html_to_md2.lua" ()

pp(traverse_array(to_walk, true))

return traverse_array
