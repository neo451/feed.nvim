local TT = require("feed.db.ttrss")
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T["get reports an empty article response"] = function()
   local remote = setmetatable({
      api = {
         getArticle = function()
            return {}
         end,
      },
   }, TT)

   local ok, err = pcall(remote.get, remote, "123")

   eq(false, ok)
   eq("TTRSS article 123 was not found", err)
end

return T
