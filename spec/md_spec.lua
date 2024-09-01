local md = require "rss.md"
local xml = require "rss.xml"

describe("element", function()
   it("should format simple element", function()
      assert.same("# arch by the way", md(xml.parse "<h1>arch by the way</h1>"))
   end)

   it("should format nested element", function()
      local expected = [[# zig `const std = @import("std")` by the way]]
      local src = [[<h1>zig<code>const std = @import("std")</code>by the way</h1>]]
      assert.same(expected, md(xml.parse(src)))
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
      local ast = xml.parse(src)
      pp(ast)
      assert.same(expected, md(ast))
   end)
end)
