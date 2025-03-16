local ut = require("feed.utils")
local layout = require("feed.config").winbar
local concat, format = table.concat, string.format
local align = ut.align

local M = {}
local hi_pattern = "%%#%s#%s%%*"

local map = {
   lualine = {
      "lualine_a_normal",
      "lualine_b_normal",
      "lualine_c_normal",
   },
}

local has_line = pcall(require, "lualine")

if has_line then
   for i = 1, 3 do
      local k = layout.order[i]
      ---@diagnostic disable-next-line: need-check-nil
      local section = layout[k]
      if section then
         if pcall(require, "lualine") then
            local color = map.lualine[i]
            section.color = color
         end
      end
   end

   for i = #layout.order, #layout.order - 2, -1 do
      local name = layout.order[i]
      ---@diagnostic disable-next-line: need-check-nil
      local section = layout[name]
      if section then
         if pcall(require, "lualine") then
            local color = map.lualine[#layout.order + 1 - i]
            section.color = color
         end
      end
   end
end

---@param name string
---@return string
function _G._feed_bar_component(name)
   local sect = layout[name]
   local width = type(sect.width) == "number" and sect.width or #name
   local color = layout[name].color
   local text
   if layout[name].format then
      text = layout[name].format()
      if text ~= "" then
         text = " " .. text .. " "
      end
   else
      text = align(name:upper(), width + 1)
   end
   return format(hi_pattern, color, text)
end

---@return string
function M.show_winbar()
   local buf = {}
   for _, name in ipairs(layout.order) do
      local text
      if not layout[name] then
         if name:find("%%") then
            text = name
         end
      else
         text = "%{%v:lua._feed_bar_component('" .. name .. "')%}"
      end
      buf[#buf + 1] = text
   end
   return concat(buf, "")
end

return M
