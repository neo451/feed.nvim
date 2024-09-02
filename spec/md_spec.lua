local md = require "rss.md"
local xml = require "rss.xml"

describe("element", function()
   it("should format simple element", function()
      assert.same("# arch by the way", md(xml.generic_parse "<h1>arch by the way</h1>"))
   end)

   it("should format nested element", function()
      local expected = [[# zig `const std = @import("std")` by the way]]
      local src = [[<h1>zig<code>const std = @import("std")</code>by the way</h1>]]
      assert.same(expected, md(xml.generic_parse(src)))
   end)

   it("should format nested element", function()
      local expected = [[# zig `const std = @import("std")` by the way]]
      local src =
      [[<md><p>Wersquo;ve updated the spec to. It’s a minor update to JSON Feed, clarifying a few things in the spec and adding a couple<code> asdad </code> new fields such as</p></md>]]
      --       local src = [[
      -- <md>
      -- <p>We&rsquo;ve updated the spec to <a href="https://jsonfeed.org/version/1.1">version 1.1</a>. It’s a minor update to JSON Feed, clarifying a few things in the spec and adding a couple new fields such as <code>authors</code> and <code>language</code>.</p><p>For version 1.1, we&rsquo;re starting to move to the more specific MIME type <code>application/feed+json</code>. Clients that parse HTML to discover feeds should prefer that MIME type, while still falling back to accepting <code>application/json</code> too.</p><p>The <a href="https://jsonfeed.org/code/">code page</a> has also been updated with several new code libraries and apps that support JSON Feed.</p>
      -- </md>
      --    ]]
      local ast = xml.generic_parse(src)
      pp(ast)
      assert.same(expected, md(ast))
   end)
end)

local src = [[

<p>We — Manton Reece and Brent Simmons — have noticed that JSON has become the developers’ choice for APIs, and that developers will often go out of their way to avoid XML. JSON is simpler to read and write, and it’s less prone to bugs.</p><p>So we developed JSON Feed, a format similar to <a href="http://cyber.harvard.edu/rss/rss.html">RSS</a> and <a href="https://tools.ietf.org/html/rfc4287">Atom</a> but in JSON. It reflects the lessons learned from our years of work reading and publishing feeds.</p><p><a href="https://jsonfeed.org/version/1">See the spec</a>. It’s at version 1, which may be the only version ever needed. If future versions are needed, version 1 feeds will still be valid feeds.</p><h4 id="notes">Notes</h4><p>We have a <a href="https://github.com/manton/jsonfeed-wp">WordPress plugin</a> and, coming soon, a JSON Feed Parser for Swift. As more code is written, by us and others, we’ll update the <a href="https://jsonfeed.org/code">code</a> page.</p><p>See <a href="https://jsonfeed.org/mappingrssandatom">Mapping RSS and Atom to JSON Feed</a> for more on the similarities between the formats.</p><p>This website — the Markdown files and supporting resources — <a href="https://github.com/brentsimmons/JSONFeed">is up on GitHub</a>, and you’re welcome to comment there.</p><p>This website is also a blog, and you can subscribe to the <a href="https://jsonfeed.org/xml/rss.xml">RSS feed</a> or the <a href="https://jsonfeed.org/feed.json">JSON feed</a> (if your reader supports it).</p><p>We worked with a number of people on this over the course of several months. We list them, and thank them, at the bottom of the <a href="https://jsonfeed.org/version/1">spec</a>. But — most importantly — <a href="http://furbo.org/">Craig Hockenberry</a> spent a little time making it look pretty. :)</p>
]]
local ast = xml.parse(src)

io.open("/home/n451/Plugins/rss.nvim/data/html_to_md2.lua", "wb"):write(vim.inspect(ast))
