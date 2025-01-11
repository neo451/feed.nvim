local github = require "feed.integrations.github"
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T["github"] = MiniTest.new_set {}

T["rsshub"] = MiniTest.new_set {}

T["github"]["works"] = function()
   local url1 = "https://github.com/neo451/feed.nvim"
   local url2 = "github://neo451/feed.nvim"
   local url3 = "neo451/feed.nvim"

   local feed = "https://github.com/neo451/feed.nvim/commits.atom"
   eq(feed, github(url1))
   eq(feed, github(url2))
   eq(feed, github(url3))

   local url4 = "neo451/feed.nvim/releases"
   eq("https://github.com/neo451/feed.nvim/releases.atom", github(url4))

   local url5 = "rsshub://neo451/feed.nvim"
   eq(url5, github(url5))
end

return T
