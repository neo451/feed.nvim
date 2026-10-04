local progress = require("feed.ui.progress")

local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T["percentage"] = function()
   eq(0, progress._percentage(0, 0))
   eq(0, progress._percentage(1, 0))
   eq(0, progress._percentage(-1, 4))
   eq(25, progress._percentage(1, 4))
   eq(100, progress._percentage(4, 4))
   eq(100, progress._percentage(5, 4))
end

return T
