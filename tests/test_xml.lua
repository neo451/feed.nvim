local xml = require("feed.parser.xml")
local eq = MiniTest.expect.equality

describe("sanitize", function()
   it("shoud handle entities in all tags", function()
      local res = xml.parse("<title>Love & Fear</title>")
      eq({ title = { "Love & Fear" } }, res)
   end)
   -- it("shoud handle CDATA", function()
   --    local res = xml.parse("<desc><![CDATA[Love & Fear]]></desc>")
   --    eq("<desc>Love &amp; Fear</desc>", res)
   -- end)
   it("should handle xhtml", function()
      local src = [[<?xml version="1.0" encoding="utf-8"?>
<content type="xhtml" xml:base="http://example.org/entry/3" xml:lang="en-US">
  <div xmlns="http://www.w3.org/1999/xhtml">Watch out for <span style="background: url(javascript:window.location='http://example.org/')"> nasty tricks</span></div>
</content> ]]
      local res = xml.parse(src, "")
      eq(
         [[<div xmlns="http://www.w3.org/1999/xhtml">Watch out for <span style="background: url(javascript:window.location='http://example.org/')"> nasty tricks</span></div>]],
         res.content[1]
      )
      eq("xhtml", res.content.type)
   end)
end)
