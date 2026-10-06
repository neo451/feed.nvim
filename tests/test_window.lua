local Win = require("feed.ui.window")
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T["closing a window without a previous window does not select nil"] = function()
   local original_set_current_win = vim.api.nvim_set_current_win
   local selected
   vim.api.nvim_set_current_win = function(win)
      selected = win
   end

   local win = Win.new({})
   win:close()
   vim.wait(1000, function()
      return win.win == nil
   end)

   vim.api.nvim_set_current_win = original_set_current_win
   eq(nil, selected)
end

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
