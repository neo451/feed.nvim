local M = {}

---@param usr_config feed.config
M.setup = function(usr_config)
   local config = require "feed.config"
   config.resolve(usr_config)
end

local render = require "feed.render"
M.get_entry = render.get_entry

return M
