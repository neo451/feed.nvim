local md = require "rss.treedoc.init"
-- local xml = require "rss.xml"

describe("element", function()
   it("should format simple element", function()
      assert.same("# arch by the way", md.parse("<h1>arch by the way</h1>", { language = "html" }))
   end)
end)
