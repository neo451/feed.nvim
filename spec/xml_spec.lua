local xml = require "feed.parser.xml"

vim.treesitter.language.add("xml", {
   path = vim.fn.expand "~/.luarocks/lib/luarocks/rocks-5.1/tree-sitter-xml/0.0.29-1/parser/xml.so",
})

describe("sanitize", function()
   it("shoud handle entities in all tags", function()
      local res = xml.sanitize "<title>Love & Fear</title>"
      assert.equal("<title>Love &amp; Fear</title>", res)
   end)
   it("shoud handle CDATA", function()
      local res = xml.sanitize "<desc><![CDATA[Love & Fear]]></desc>"
      assert.equal("<desc>Love &amp; Fear</desc>", res)
      local res2 = xml.sanitize [=[
   <![CDATA[
          
                    <p>I joined Mastodon in 2018. It was one of many days on Twitter that felt like it’s finally enough. I don’t exactly remember why. Twitter has been my social home on the internet since 2008 and it boosted my career in many ways. I made a lot of friends there. Some online friends turned into offline friends, into friends for life. But Twitter changed over the years.</p>
]]>

         ]=]
   end)
   it("should handle xhtml", function()
      local src = [[<?xml version="1.0" encoding="utf-8"?>
<content type="xhtml" xml:base="http://example.org/entry/3" xml:lang="en-US">
  <div xmlns="http://www.w3.org/1999/xhtml">Watch out for <span style="background: url(javascript:window.location='http://example.org/')"> nasty tricks</span></div>
</content> ]]
      local res = xml.parse(src, "")
      assert.same(
         [[<div xmlns="http://www.w3.org/1999/xhtml">Watch out for <span style="background: url(javascript:window.location='http://example.org/')"> nasty tricks</span></div>]],
         res.content[1]
      )
      assert.same("xhtml", res.content.type)
   end)
end)
