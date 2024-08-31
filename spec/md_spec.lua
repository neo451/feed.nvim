local md = require("rss.md")
local xml = require("rss.xml")

describe("element", function()
	it("should format simple element", function()
		assert.same("# arch by the way", md(xml.parse("<h1>arch by the way</h1>")))
	end)

	it("should format nested element", function()
		local expected = [[# zig `const std = @import("std")` by the way]]
		local src = [[<h1>zig<code>const std = @import("std")</code>by the way</h1>]]
		assert.same(expected, md(xml.parse(src)))
	end)
end)
