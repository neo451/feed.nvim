local health = require "feed.health"
local ut = require "feed.utils"

--- FIX: wrap with current window width, and config.opt wrap false

---@param resource string
---@param cb fun(lines: string[])
---@param is_src? boolean
local function convert(resource, cb, is_src)
   if not health.check_binary_installed { name = "pandoc", min_ver = 3 } then
      cb { "you need pandoc to view feeds https://pandoc.org" }
   end
   local sourced_file = debug.getinfo(2, "S").source:sub(2)
   local filter = vim.fn.fnamemodify(sourced_file, ":h:h") .. "/feed/ui/pandoc_writer.lua"

   local function process(obj)
      if obj.code ~= 0 then
         return cb { "pandoc failed: " .. obj.stderr }
      end
      local str = ut.unescape(obj.stdout)
      vim.schedule(function()
         return cb(vim.split(str, "\n"))
      end)
   end

   local cmd = {
      "pandoc",
      ut.looks_like_url(resource) and "-r" or "-f",
      "html",
      "-t",
      filter,
      "--wrap=none",
      (not is_src) and resource,
   }
   vim.system(cmd, { text = true, stdin = resource }, process)
end

return { convert = convert }
