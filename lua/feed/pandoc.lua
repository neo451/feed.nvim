local health = require("feed.health")
local ut = require("feed.utils")

---@class pandoc_args
---@field link string
---@field src string
---@field id string
---@field from string
---@field to string
---@field homeUrl string TODO:

---pandoc wrapper
---@param ctx any
---@return vim.SystemCompleted?
local function convert(ctx)
   local db = require("feed.db")
   local link = ctx.link
   local src = ctx.src
   local fp = ctx.id and tostring(db.dir / "data" / ctx.id) or nil
   local from = ctx.from or "html"
   local to = ctx.to or vim.api.nvim_get_runtime_file("scripts/gfm.lua", false)[1]
   local stdout = ctx.stdout
   local on_exit = ctx.on_exit

   if not health.check_binary_installed({ name = "pandoc", min_ver = 3 }) then
      vim.schedule_wrap(vim.notify)("you need **pandoc** to view feeds https://pandoc.org")
      return
   end

   local cmd = {
      "pandoc",
      link and "-r" or "-f",
      from,
      "-t",
      to,
      "--wrap=none",
      link or fp,
   }

   if vim.g.feed_debug then
      vim.notify("pandoc cmd running: " .. table.concat(cmd, " "))
   end

   if on_exit and stdout then
      vim.system(cmd, {
         text = true,
         stdin = src,
         -- TODO: log err
         stdout = vim.schedule_wrap(function(err, data)
            if data then
               return stdout(ut.unescape(data))
            end
         end),
      }, vim.schedule_wrap(on_exit))
   else
      local obj = vim.system(cmd, {
         text = true,
         stdin = src,
      }):wait()
      obj.stdout = ut.unescape(obj.stdout)
      return obj
   end
end

return { convert = convert }
