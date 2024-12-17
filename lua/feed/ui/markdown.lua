local health = require("feed.health")
local ut = require("feed.utils")

--- FIX: wrap with current window width, and config.opt wrap false
--- FIX: strip html comments

---@param resource string
---@param cb fun(lines: string[])
---@param is_src? boolean
---@param fp? string
local function convert(resource, cb, is_src, fp)
   if not health.check_binary_installed({ name = "pandoc", min_ver = 3 }) then
      cb({ "you need pandoc to view feeds https://pandoc.org" })
   end

   local function process(obj)
      if obj.code ~= 0 then
         return cb({ "pandoc failed: " .. obj.stderr })
      end
      vim.schedule(function()
         return cb(vim.split(obj.stdout, "\n"))
      end)
   end

   local cmd = vim.tbl_flatten {
      "pandoc",
      ut.looks_like_url(resource) and "-r" or "-f",
      "html",
      "-t",
      vim.api.nvim_get_runtime_file("lua/feed/ui/pandoc_writer.lua", false)[1],
      "--wrap=none",
      (not is_src) and resource,
      fp and { '-o', fp } or nil,
   }

   vim.system(cmd, { text = true, stdin = resource }, process)
end

return { convert = convert }
