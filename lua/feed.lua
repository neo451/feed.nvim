local M = {}

---@param usr_config feed.config
M.setup = function(usr_config)
   local config = require "feed.config"
   config.resolve(usr_config)
   local cmds = require "feed.commands"
   cmds._prepare_bufs() -- just create to avoid next time open editor and disrupt jumplist ...
   local render = require "feed.render"

   M.get_entry = render.get_entry
end

setmetatable(M, {
   __index = function(self, k)
      if not rawget(self, k) then
         return rawget(require "feed.commands", k)
      end
   end,
})

return M
