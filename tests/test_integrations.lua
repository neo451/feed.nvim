local github = require("feed.integrations.github")
local rsshub = require("feed.integrations.rsshub")
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T["github"] = MiniTest.new_set({})

T["rsshub"] = MiniTest.new_set({})

T["rsshub"]["works"] = function()
   local config = require("feed.config")
   config.rsshub.instance = "127.0.0.1"

   local url = "rsshub://163/exclusive/fd"

   eq("127.0.0.1/163/exclusive/fd", rsshub(url))
end

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
