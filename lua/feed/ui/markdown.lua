local health = require "feed.health"
local ut = require "feed.utils"
---@type feed.db
local db = ut.require "feed.db"

local function id2html(id)
   local link = db[id].link
   if link then
      local res = vim.system({ "curl", link }, { text = true }):wait()
      local temp = vim.fn.tempname()
      ut.save_file(temp, res.stdout)
      return temp
   end
end

local function convert(id, full_fetch)
   if not health.check_binary_installed { name = "pandoc", min_ver = 3 } then
      return "you need pandoc to view feeds https://pandoc.org"
   end
   local sourced_file = require("plenary.debug_utils").sourced_filepath()
   local filter = vim.fn.fnamemodify(sourced_file, ":h") .. "/pandoc_writer.lua"
   local fp = db.dir .. "/data/" .. id

   if full_fetch and ut.read_file(fp) == "empty entry" then
      fp = id2html(id)
   end

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
      return "pandoc failed: " .. obj.stderr
   end
   return ut.unescape(obj.stdout)
end

return {
   convert = convert,
}
