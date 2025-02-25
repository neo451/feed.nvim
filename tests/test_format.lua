local M = require("feed.ui.format")
local eq = MiniTest.expect.equality
local db = require("feed.db")

local T = MiniTest.new_set()
local layout = require("feed.config").layout

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

db.__index = db

function db:get_tags(id)
   local ret = {}
   -- 1. auto tag no [read] as [unread]
   if not (self.tags.read and self.tags.read[id]) then
      ret = { "unread" }
   end

   -- 2. get tags from tags.lua
   for tag, tagees in pairs(self.tags) do
      if tagees[id] then
         ret[#ret + 1] = tag
      end
   end
   return ret
end

T["format"] = MiniTest.new_set({})

T.format["tags"] = function()
   local id = "1"
   local expect = "[unread, star]"
   eq(expect, M.tags(id, db))
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
   local expect = "2025-01-01 neovim                    [unread, star]       title "
   eq(expect, M.entry(id, layout, db))
end

return T
