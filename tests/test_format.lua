local eq = MiniTest.expect.equality
local sha = vim.fn.sha256

local T = MiniTest.new_set()
local layout = require("feed.config")._default.ui

local db = require("feed.db")
db = db.new("~/.feed.nvim.test/")

db.feeds["url"] = {
   title = "Neovim",
   tags = { "nvim" },
}

db["1"] = {
   title = "title",
   feed = "url",
   author = "author",
   link = "link",
   time = os.time({ year = 2025, month = 1, day = 1 }),
}

db:tag(sha("1"), "star")

local ui = require("feed.ui")

T["format"] = MiniTest.new_set({})

-- T.format["tags"] = function()
--    local id = "1"
--    local expect = "[unread, star]"
--    eq(expect, M.tags(id, db))
-- end
--
-- T.format["title"] = function()
--    local id = "1"
--    eq("title", M.title(id, db))
-- end
--
-- T.format["feed"] = function()
--    local id = "1"
--    eq("neovim", M.feed(id, db))
-- end
--
-- T.format["date"] = function()
--    local id = "1"
--    eq("2025-01-01", M.date(id, db))
-- end

T.format["headline"] = function()
   local id = "1"
   -- TODO:
   local expect = "2025-01-01 Neovim                    [unread]             title "
   eq(expect, ui._format_headline(id, layout, db))
end

return T
