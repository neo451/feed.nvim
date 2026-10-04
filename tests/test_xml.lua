local xml = require("feed.parser.xml")
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T["handles entities in all tags"] = function()
   local res = xml.parse("<title>Love & Fear</title>")
   eq({ title = { "Love & Fear" } }, res)
end

T["decodes Unicode numeric character references"] = function()
   local res = xml.parse("<title>&#8217;&#x2026;</title>")
   eq({ title = { "’…" } }, res)
end

T["ignores comments around the document element"] = function()
   local src = '<?xml version="1.0" encoding="UTF-8"?><!-- before --><rss></rss><!-- after -->'
   local res = xml.parse(src)
   eq("UTF-8", res.encoding)
   eq("", res.rss)
end

T["handles xhtml"] = function()
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
end

return T
