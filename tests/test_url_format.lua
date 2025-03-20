local eq = MiniTest.expect.equality
local import = require("feed.utils").extend_import_url
local export = require("feed.utils").extend_export_url

local T = MiniTest.new_set()

T["import"] = MiniTest.new_set({})
T["export"] = MiniTest.new_set({})

T["import"]["rsshub"] = function()
   local url = "rsshub://163/exclusive/fd"
   local expect = "https://rsshub.app/163/exclusive/fd?format=json?mode=fulltext"
   eq(expect, import(url))
end

T["export"]["rsshub"] = function()
   local url = "https://rsshub.app/163/exclusive/fd"
   local expect = "https://rsshub.app/163/exclusive/fd"
   eq(expect, export(url))
end

T["import"]["github"] = function()
   local url2 = "github://neo451/feed.nvim"
   local url3 = "neo451/feed.nvim"

   local feed = "https://github.com/neo451/feed.nvim/commits.atom"
   eq(feed, import(url2))
   eq(feed, import(url3))

   local url4 = "neo451/feed.nvim/releases"
   eq("https://github.com/neo451/feed.nvim/releases.atom", import(url4))
end

T["import"]["reddit"] = function()
   local url = "r/neovim"
   local expect = "https://www.reddit.com/r/neovim.rss"
   eq(expect, import(url))
end

return T
