local M = require("feed.ui.format")
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

local db = {
   ["1"] = {
      title = "title",
      feed = "https://neovim.io/news.xml",
      author = "author",
      link = "link",
      time = os.time({ year = 2025, month = 1, day = 1 }),
   },
   feeds = {
      ["https://neovim.io/news.xml"] = {
         title = "neovim",
         tags = { "nvim" },
      },
   },
   tags = {
      star = {
         ["1"] = true,
      },
   },
}

T["format"] = MiniTest.new_set({})

T.format["tags"] = function()
   local id = "1"
   eq("[unread, star]", M.tags(id, db))
end

T.format["title"] = function()
   local id = "1"
   eq("title", M.title(id, db))
end

T.format["feed"] = function()
   local id = "1"
   eq("neovim", M.feed(id, db))
end

T.format["date"] = function()
   local id = "1"
   eq("2025-01-01", M.date(id, db))
end

T.format["entry"] = function()
   local id = "1"
   local expect = "neovim               [unread, star]       title "
   eq(expect, M.entry(id, nil, db))
end

return T
