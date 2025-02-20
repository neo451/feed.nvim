local M = require("feed.ui.markdown")
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T["convert"] = MiniTest.new_set()

T['convert']['works'] = function()
   local entry = {
      a = "b",
      time = os.time({
         year = 2025,
         month = 1,
         day = 1,
      })
   }
   local md = M.convert({
      src = [[ <h1>Hello</h1> <p>World</p> ]],
      metadata = entry
   })
   eq([[# Hello

World
]], md)
end

return T
