local M = {}
local date = require "feed.parser.date"
local config = require "feed.config"
local ut = require "feed.utils"
local db = ut.require "feed.db"
local _, MiniIcons = pcall(require, "mini.icons")

local align = ut.align

-- TODO: this whole module should be user definable

-- TODO: move to config
local tag2emoji = {
   pod = "📻", -- "󰈣",
   unread = "👀",
   read = "✅",
   star = "🌟",
   news = "📰",
   tech = "🦾",
   app = "📱",
   blog = "📝",
   email = "📧",
   -- zig = MiniIcons.get("file", "file.zig"),
   -- linux = MiniIcons.get('os', 'linux')
}

---@param tags string[]
---@return string
function M.tags(tags)
   if not tags then
      return tag2emoji and "[👀]" or "[unread]"
   end
   if not tags["read"] then
      tags["unread"] = true
   end
   local taglist = vim.iter(vim.spairs(tags))
      :map(function(k)
         if tag2emoji[k] then
            return tag2emoji[k]
         end
         return k
      end)
      :totable()
   return "[" .. table.concat(taglist, ", ") .. "]"
end

---return a format info for an entry base on user config
---@param entry feed.entry
---@param comps table
---@return table
function M.get_entry_format(entry, comps)
   local acc_width = 0
   local res = {}
   for _, v in ipairs(comps) do
      local text = entry[v[1]] or ""
      if v[1] == "tags" then
         text = M.tags(entry.tags)
      elseif v[1] == "feed" then
         if db.feeds[entry.feed] then
            text = db.feeds[entry.feed].title
         else
            text = entry.feed
         end
      elseif v[1] == "date" then
         text = date.parse(entry.time):format(config.date_format)
      end
      text = align(text, v.width, v.right_justify) .. " "
      res[#res + 1] = { color = v.color, width = acc_width, right_justify = v.right_justify, text = text }
      acc_width = acc_width + v.width + 1
   end
   return res
end

---@param entry feed.entry
---@return string
function M.entry_name(entry)
   local buf = {}
   local comps = M.get_entry_format(entry, {
      { "feed", width = 15 },
      { "tags", width = 15 },
      { "title", width = 80 },
   })
   for _, v in ipairs(comps) do
      buf[#buf + 1] = v.text
   end
   return table.concat(buf, " ")
end

return M
