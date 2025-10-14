local M = require("feed.opml")
local h = dofile("tests/helpers.lua")
local readfile = h.readfile
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()
T["import"] = MiniTest.new_set()
T["export"] = MiniTest.new_set()

T["import"]["simple opml"] = function()
   local opml = M.import([[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>%s</title></head><body>
<outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
</body></opml>]])
   assert(opml, "")
   eq(opml.http.title, "hello")
   eq(opml.http.tags, nil)
end

T["import"]["real big opml"] = function()
   local str = readfile("opml_cn.xml")
   local feeds = M.import(str)
   assert(feeds, "")
   local str2 = M.export(feeds)
   local feeds2 = M.import(str2)
   assert(feeds2, "")
   eq(feeds, feeds2)
end

T["import"]["nested opml"] = function()
   local str = readfile("opml_web.xml")
   local feeds = M.import(str)
   assert(feeds, "")
   eq({ "test_nested", "frontend" }, feeds["http://gruntjs.com/rss"].tags)
end

T["export"]["export imported opml"] = function()
   local str = [[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>feed.nvim export</title></head><body>
<outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
<outline text="hello2" title="hello" type="rss" xmlUrl="http2" htmlUrl="https"/>
</body></opml>]]
   local feeds = M.import(str)
   assert(feeds, "")
   local str2 = M.export(feeds)
   local feeds2 = M.import(str2)
   eq(feeds, feeds2)
end

return T
