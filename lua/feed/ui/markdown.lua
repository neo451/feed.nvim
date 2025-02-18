local health = require("feed.health")
local ut = require("feed.utils")

local function convert(ctx)
   local cb = ctx.cb
   local link = ctx.link
   local src = ctx.src
   local fp = ctx.fp

   if not health.check_binary_installed({ name = "pandoc", min_ver = 3 }) then
      vim.schedule_wrap(cb)({ "you need pandoc to view feeds https://pandoc.org" })
      return
   end

   local function process(obj)
      if obj.code ~= 0 then
         return vim.schedule_wrap(cb)({ "pandoc failed: " .. obj.stderr })
      end
      return vim.schedule_wrap(cb)(vim.split(obj.stdout, "\n"))
   end

   local cmd = vim.tbl_flatten({
      "pandoc",
      link and "-r" or "-f",
      "html",
      "-t",
      vim.api.nvim_get_runtime_file("lua/feed/ui/pandoc_writer.lua", false)[1],
      "--wrap=none",
      link or fp,
   })

   if not cb then
      return vim.system(cmd, { text = true, stdin = src }):wait().stdout
   else
      vim.system(cmd, { text = true, stdin = src }, process)
   end
end

return { convert = convert }
