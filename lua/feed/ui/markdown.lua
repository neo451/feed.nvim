local health = require "feed.health"
local ut = require "feed.utils"

---@param fp string
---@return string[]
local function convert(fp)
   if not health.check_binary_installed { name = "pandoc", min_ver = 3 } then
      return { "you need pandoc to view feeds https://pandoc.org" }
   end
   local sourced_file = require("plenary.debug_utils").sourced_filepath()
   local filter = vim.fn.fnamemodify(sourced_file, ":h") .. "/pandoc_writer.lua"

   local cmd = {
      "pandoc",
      "-f",
      "html",
      "-t",
      filter,
      "--wrap=none",
      fp,
   }
   local obj = vim.system(cmd, { text = true }):wait()
   if obj.code ~= 0 then
      return { "pandoc failed: " .. obj.stderr }
   end
   local str = ut.unescape(obj.stdout)
   return vim.split(str, "\n")
end

return {
   convert = convert,
}
