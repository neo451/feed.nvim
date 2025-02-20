local M = {}

-- TODO: soft deprecate this, can still use, won't be documented, lazy.lua opts remove

---@param usr_config feed.config
M.setup = function(usr_config)
   require("feed.config").resolve(usr_config)
   require("feed.db"):soft_sync()

   for k, v in pairs(require("feed.commands")) do
      if not vim.startswith(k, "_") then
         M[k] = v.impl
      end
   end

   local ui = require("feed.ui")
   M.get_entry = ui.get_entry
end

return M
