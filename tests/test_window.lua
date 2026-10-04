local Win = require("feed.ui.window")
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T["directly closing a zen window also closes its backdrop"] = function()
   local win = Win.new({
      zen = true,
      width = 20,
      height = 5,
   })
   local backdrop = win.backdrop

   vim.api.nvim_win_close(win.win, true)

   eq(
      true,
      vim.wait(1000, function()
         return not backdrop:win_valid() and not backdrop:buf_valid()
      end)
   )
end

return T
