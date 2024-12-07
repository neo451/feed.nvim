local M = {}
local Config = require "feed.config"
local ut = require "feed.utils"
local _, MiniIcons = pcall(require, "mini.icons") -- TODO:

local align = ut.align
local tag2icon = Config.tag2icon

-- TODO: this whole module should be user definable

-- TODO: move to config

local function cleanup(str)
   return vim.trim(str:gsub("\n", ""))
end

---@param entry feed.entry
---@return string
function M.tags(entry)
   local tags = entry.tags
   if not tags then
      return tag2icon and "[👀]" or "[unread]"
   end
   if not tags["read"] then
      tags["unread"] = true
   end
   local taglist = vim.iter(vim.spairs(tags))
      :map(function(k)
         if tag2icon[k] then
            return tag2icon[k]
         end
         return k
      end)
      :totable()
   return "[" .. table.concat(taglist, ", ") .. "]"
end

---@param entry feed.entry
---@return string
M.title = function(entry)
   return cleanup(entry.title)
end

---@param entry feed.entry
---@return string
M.feed = function(entry)
   return cleanup(entry.feed)
end

M.author = function(entry)
   return cleanup(entry.author)
end

M.link = function(entry)
   return entry.link
end

---@param entry feed.entry
---@return string
function M.date(entry)
   ---@diagnostic disable-next-line: return-type-mismatch
   return os.date(Config.date_format, entry.time)
end

---@param entry feed.entry
---@param comps table?
---@return string
function M.entry(entry, comps)
   local buf = {}
   comps = comps or {
      { "feed", width = 15 },
      { "tags", width = 5 },
      { "title", width = 80 },
   }

   for _, v in ipairs(M.gen_format(entry, comps)) do
      buf[#buf + 1] = v.text
   end
   return table.concat(buf, " ")
end

---return a format info for an entry base on user config
---@param entry feed.entry
---@param comps table
---@return table
function M.gen_format(entry, comps)
   local acc_width = 0
   local res = {}
   for _, v in ipairs(comps) do
      local text = entry[v[1]] or ""
      if M[v[1]] then
         text = M[v[1]](entry)
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
---@param entry feed.entry
---@param comps table
---@return NuiLine
function M.gen_nui_line(entry, comps)
   local NuiLine = require "nui.line"
   local line = NuiLine()
   if not entry then
      return NuiLine()
   end
   for _, v in ipairs(comps) do
      local text = entry[v[1]] or ""
      if M[v[1]] then
         text = M[v[1]](entry)
      end
      line:append(align(text, v.width + 1, v.right_justify), v.color)
   end
   return line
end

return M
