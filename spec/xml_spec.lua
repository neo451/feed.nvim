local xml = require "feed.parser.xml"

local sourced_file = require("plenary.debug_utils").sourced_filepath()
local data_dir = vim.fn.fnamemodify(sourced_file, ":h") .. "/outliers/"

local function readfile(path, pre)
   pre = pre or data_dir
   local str = vim.fn.readfile(pre .. path)
   return table.concat(str)
end

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
end)

-- describe("sanitize real bad files", function()
--    it("should do html in rss titles", function()
--       local str = readfile "Web Platform News.xml"
--       local ast = xml.parse(str)
--       assert.equal("The difference between <code>:disabled</code> and <code>[disabled]</code> in CSS", ast.rss.channel.item[2].title)
--    end)
--    it("should do html in rss titles", function()
--       local str = readfile "Bastian Allgeier’s Journal.xml"
--       local ast = xml.parse(str, "Bastian Allgeier’s Journal.xml")
--       -- assert.equal("The difference between <code>:disabled</code> and <code>[disabled]</code> in CSS", ast.rss.channel.item[2].title)
--    end)
-- end)
