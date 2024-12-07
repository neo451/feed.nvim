local health = require "feed.health"
local ut = require "feed.utils"

---@param fp string
---@param cb fun(lines: string[])
local function convert(fp, cb)
   if not health.check_binary_installed { name = "pandoc", min_ver = 3 } then
      cb { "you need pandoc to view feeds https://pandoc.org" }
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
   vim.system(cmd, { text = true }, function(obj)
      if obj.code ~= 0 then
         return cb { "pandoc failed: " .. obj.stderr }
      end
      local str = ut.unescape(obj.stdout)
      return cb(vim.split(str, "\n"))
   end)
end

return {
   convert = convert,
}
