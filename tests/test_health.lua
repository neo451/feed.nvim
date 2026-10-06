local health = require("feed.health")
local eq = MiniTest.expect.equality

local original_executable = vim.fn.executable
local original_system = vim.system

local T = MiniTest.new_set({
   hooks = {
      post_case = function()
         vim.fn.executable = original_executable
         vim.system = original_system
      end,
   },
})

T["binary checks handle missing version output"] = function()
   vim.fn.executable = function()
      return 1
   end
   vim.system = function()
      return {
         wait = function()
            return { stdout = nil }
         end,
      }
   end

   eq(false, health.check_binary_installed({ name = "fake", min_ver = 1 }))
end

return T
