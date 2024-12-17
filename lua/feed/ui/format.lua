local M = {}
local Config = require "feed.config"
local DB = require "feed.db"
local ut = require "feed.utils"

local align = ut.align
local tag2icon = Config.tag2icon

-- TODO: this whole module should be user definable


---@param str string
---@return string
local function cleanup(str)
   return vim.trim(str:gsub("\n", ""))
end

---@param id string
---@return string
function M.tags(id)
   local taglist = vim.iter(DB.tags)
       :fold({}, function(acc, tag, v)
          if v[id] then
             if tag2icon.enabled then
                acc[#acc + 1] = tag2icon[tag] or tag
             else
                acc[#acc + 1] = tag
             end
          end
          return acc
       end)
   if vim.tbl_isempty(taglist) then
      if tag2icon.enabled then
         taglist = { tag2icon.unread }
      else
         taglist = { 'unread' }
      end
   end
   return "[" .. table.concat(taglist, ", ") .. "]"
end

---@param id string
---@return string
---@return string
M.title = function(id)
   local entry = DB[id]
   return cleanup(entry.title), "FeedTitle"
end

---@param id string
---@return string
---@return string
M.feed = function(id)
   local entry = DB[id]
   local feed = DB.feeds[entry.feed] and DB.feeds[entry.feed].title or entry.feed
   return cleanup(feed), "FeedTitle" -- FIX: for ttrss
end

---@param id string
---@return string
---@return string
M.author = function(id)
   ---@type feed.entry
   local entry = DB[id]
   local text
   if entry.author == "" then
      text = entry.feed
   else
      text = entry.author
   end
   return cleanup(text), "FeedTitle"
end

---@param id string
---@return string
---@return string
M.link = function(id)
   return DB[id].link, "FeedLink"
end

---@param id string
---@return string
---@return string
M.date = function(id)
   ---@diagnostic disable-next-line: return-type-mismatch
   return os.date(Config.date_format, DB[id].time), "FeedTitle"
end

---@param id string
---@param comps table?
---@return string
M.entry = function(id, comps)
   local buf = {}
   comps = comps or {
      { "feed",  width = 15 },
      { "tags",  width = 5 },
      { "title", width = 80 },
   }

   for _, v in ipairs(M.gen_format(id, comps)) do
      buf[#buf + 1] = v.text
   end
   return table.concat(buf, " ")
end

---return a format info for an entry base on user config
---@param id string
---@param comps table
---@return table
function M.gen_format(id, comps)
   local acc_width = 0
   local res = {}
   for _, v in ipairs(comps) do
      local text = DB[id][v[1]] or ""
      if M[v[1]] then
         text = M[v[1]](id)
      end
      v.width = v.width or #text
      v.width = v[1] == "title" and vim.api.nvim_win_get_width(0) - acc_width - 1 or v.width
      text = align(text, v.width, v.right_justify) .. " "
      res[#res + 1] = { color = v.color, width = acc_width, right_justify = v.right_justify, text = text }
      acc_width = acc_width + v.width + 1
   end
   return res
end

---return a NuiLine obj for an entry base on user config
---@param id string
---@param comps table
---@return NuiLine
function M.gen_nui_line(id, comps)
   local NuiLine = require "nui.line"
   local line = NuiLine()
   local acc_width = 0
   local entry = DB[id]
   if not entry then
      return NuiLine()
   end
   for _, v in ipairs(comps) do
      local text = entry[v[1]] or ""
      if M[v[1]] then
         text = M[v[1]](id)
      end
      local width = v[1] == "title" and vim.api.nvim_win_get_width(0) - acc_width - 1 or v.width
      line:append(align(text, width + 1, v.right_justify), v.color)
      acc_width = acc_width + v.width + 1
   end
   return line
end

return M
