---@class feed.api: feed.ui
---@field db feed.db
---@field parse function
local M = {}

---@param usr_config feed.config
M.setup = function(usr_config)
   require("feed.config").resolve(usr_config)
   require("feed.db"):setup_sync(usr_config.feeds)
end

setmetatable(M, {
   __index = function(_, k)
      if k == "db" then
         return require("feed.db")
      elseif k == "parse" then
         return require("feed.parser").parse
      end
      return require("feed.ui")[k]
   end,
})

_G.Feed = M

return M
