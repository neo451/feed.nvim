vim.treesitter.language.add("html", {
   path = vim.fn.expand "~/.local/share/nvim/lazy/nvim-treesitter/parser/html.so",
})

vim.treesitter.language.add("xml", {
   path = vim.fn.expand "~/.local/share/nvim/lazy/nvim-treesitter/parser/xml.so",
})

local treedoc = require "treedoc"
local assert = require "luassert"
local eq = assert.are.same

local sourced_file = require("plenary.debug_utils").sourced_filepath()
local data_dir = vim.fn.fnamemodify(sourced_file, ":h") .. "/data/"

local function xml(src)
   return treedoc.parse(src, { language = "xml" })
end

describe("xml element", function()
   it("should do simple elements", function()
      eq({ title = "arch by the way" }, xml("<title>arch by the way</title>")[1])
   end)
   it("should do nested elements", function()
      local src2 = [[<pre>
<channel>
		<title>arch</title>
		<link>https://archlinux.org/feeds/news/</link>
</channel>
</pre>]]
      local expected = {
         pre = {
            channel = {
               title = "arch",
               link = "https://archlinux.org/feeds/news/",
            },
         },
      }
      eq(expected, xml(src2)[1])
   end)
   it("should do attrs", function()
      local src = [[<rss version="2.0">rss feeds here</rss>]]
      local expected = { rss = { version = "2.0", [1] = "rss feeds here" } }
      eq(expected, xml(src)[1])
   end)
   it("should put same named tags into one array", function()
      local src = [[<rss>
<item>1</item>
<item>2</item>
<item>3</item>
</rss>]]
      local expected = { rss = { item = { "1", "2", "3" } } }
      eq(expected, xml(src)[1])
   end)
end)

local function readfile(path)
   local str = vim.fn.readfile(data_dir .. path)
   return table.concat(str)
end

describe("acutual rss feed", function()
   it("should produce simple lua table", function()
      local str = readfile "rss_example_2.0.xml"
      local ast = xml(str)[1]
      eq("2.0", ast.rss.version)

      str = readfile "rss_example_0.92.xml"
      ast = xml(str)[1]
      eq("0.92", ast.rss.version)

      str = readfile "rss_example_0.91.xml"
      ast = xml(str)[1]
      eq("0.91", ast.rss.version)
   end)
end)

describe("acutual atom feed", function()
   it("should produce simple lua table", function()
      local str = readfile "atom_example.xml"
      local ast = xml(str)[1]
      eq("http://www.w3.org/2005/Atom", ast.feed.xmlns)
   end)
end)
