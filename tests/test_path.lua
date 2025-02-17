local M = require("feed.db.path")
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T["path"] = MiniTest.new_set()

-- T["path"]["new"] = function()
--    local obj = M("~/.feed.path/test/")
--    eq({ "", "home", "n451", ".feed.path", "test" }, obj.path)
-- end
--
-- T["path"]["__div"] = function()
--    local obj = M("~/.feed.path/test/") / "test_sub"
--    eq({ "", "home", "n451", ".feed.path", "test", "test_sub" }, obj.path)
-- end
--
-- T["path"]["save"] = function()
--    local obj = M("~/.feed.path/") / "feeds.lua"
--    obj:save({
--       1,
--       { title = "neovim" },
--       "hi",
--    })
-- end
--
-- T["path"]["load"] = function()
--    local obj = M("~/.feed.path/") / "feeds.lua"
--    eq(obj:load(), {
--       1,
--       { title = "neovim" },
--       "hi",
--    })
-- end
--
-- T["path"]["touch"] = function()
--    local obj = M("~/.feed.path/") / "feeds2.lua"
--    obj:touch()
--    eq(obj:read(), "")
-- end
--
-- T["path"]["mkdir"] = function()
--    local obj = M("~/.feed.path/") / "object"
--    obj:mkdir()
--    eq(vim.uv.fs_stat(tostring(obj)).type, "directory")
-- end

return T
