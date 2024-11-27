local m = require "feed.parser"
local eq = assert.are.same
local date = require "feed.parser.date"
local h = require "spec.helpers"
local is_url = h.is_url
local readfile = h.readfile

vim.treesitter.language.add("html", {
   path = vim.fn.expand "~/.luarocks/lib/luarocks/rocks-5.1/tree-sitter-html/0.0.29-1/parser/html.so",
})

vim.treesitter.language.add("xml", {
   path = vim.fn.expand "~/.luarocks/lib/luarocks/rocks-5.1/tree-sitter-xml/0.0.29-1/parser/xml.so",
})

local check_feed = function(ast)
   assert.is_string(ast.title, "no title")
   assert.is_string(ast.desc, "not desc")
   is_url(ast.link)
   assert.is_table(ast.entries)
   for _, v in ipairs(ast.entries) do
      if not v.link then
         vim.print(ast)
      end
      is_url(v.link, "no link")
      assert.is_number(v.time, "no time")
      assert.is_string(v.id, "no id")
      assert.is_string(v.title, "no title")
      assert.is_string(v.author, "no author")
      assert.is_string(v.feed, "no feed")
   end
end

local check_feed_minimal = function(ast)
   -- assert.is_string(ast.title, "no title")
   assert.is_string(ast.version)
   assert.is_table(ast.entries)
end

local dump_date = function(time)
   return os.date("%Y-%m-%d", time)
end

describe("rss", function()
   it("should reify to unified format", function()
      local f = m.parse_src(readfile "rss_0.91.xml", "http://placehoder.feed")
      eq("rss091", f.version)
      check_feed(f)

      f = m.parse_src(readfile "rss_2.0.xml", "http://placehoder.feed")
      eq("rss20", f.version)
      check_feed(f)

      f = m.parse_src(readfile "rss_0.92.xml", "http://placehoder.feed")
      eq("rss092", f.version)
      check_feed(f)

      f = m.parse_src(readfile "rss_ns.xml", "http://placehoder.feed")
      eq("rss20", f.version)
      eq("2002-09-04", dump_date(f.entries[1].time))
      eq("For documentation only", f.desc)
      eq("Mark Pilgrim (mark@example.org)", f.entries[1].author)
      check_feed(f)

      f = m.parse_src(readfile "rss_pod.xml", "http://placehoder.feed")
      eq("rss20", f.version)
      eq("2024-10-31", dump_date(f.entries[1].time))
      eq("Kris Jenkins", f.entries[1].author)
      check_feed(f)

      f = m.parse_src(readfile "rss_atom.xml", "http://placehoder.feed")
      eq("rss20", f.version)
      eq("2021-06-14", dump_date(f.entries[1].time))
      check_feed(f)

      f = m.parse_src(readfile "rdf.xml", "http://placehoder.feed")
      eq("rss10", f.version)
      check_feed(f)
   end)
end)

describe("atom", function()
   it("should parse", function()
      local f = m.parse_src(readfile "atom10.xml", "http://placehoder.feed")
      eq("atom10", f.version)
      check_feed(f)

      f = m.parse_src(readfile "atom03.xml", "http://placehoder.feed")
      eq("atom03", f.version)
      check_feed(f)

      f = m.parse_src(readfile "atom_html_content.xml", "http://placehoder.feed")
      check_feed(f)
   end)
end)

describe("json", function()
   it("should parse", function()
      local f = m.parse_src(readfile "json1.json", "http://placehoder.feed")
      eq("json1", f.version)
      check_feed(f)
      local f = m.parse_src(readfile "json2.json", "http://placehoder.feed")
      eq("json1", f.version)
      check_feed(f)
   end)
end)

describe("url resolve", function()
   it("resolve in atom, fallback to feed link?", function()
      local src = [[
<?xml version="1.0" encoding="utf-8"?>
<feed version="0.3">
<title>Sample Feed</title>
<tagline>For documentation only</tagline>
<link rel="alternate" type="text/html" href="index.html"/>
<entry xml:base="http://example.org/archives/">
<title>First entry title</title>
<link rel="alternate" type="text/html" href="000001.html"/>
<author>
<name>Mark Pilgrim</name>
<url>../about/</url>
<email>mark@example.org</email>
</author>
</entry>
</feed>]]
      local f = m.parse_src(src, "https://placehoder.feed")
      eq(f.link, "https://placehoder.feed/index.html")
      eq(f.entries[1].link, "http://example.org/archives/000001.html")

      src = [[ <?xml version="1.0" encoding="utf-8"?>
<feed version="0.3" xml:base="https://example.org">
<title>Sample Feed</title>
<tagline>For documentation only</tagline>
<link rel="alternate" type="text/html" href="index.html"/>
<entry xml:base="http://example.org/archives/">
<title>First entry title</title>
<link rel="alternate" type="text/html" href="000001.html"/>
<author>
<name>Mark Pilgrim</name>
<url>../about/</url>
<email>mark@example.org</email>
</author>
</entry>
</feed>]]
      f = m.parse_src(src, "https://placehoder.feed")
      eq(f.link, "https://example.org/index.html")
      eq(f.entries[1].link, "http://example.org/archives/000001.html")
   end)
end)

describe("feedparser test suite", function()
   it("atom", function()
      for f in vim.fs.dir "./spec/data/atom" do
         local str = readfile(f, "./spec/data/atom/")
         check_feed_minimal(m.parse_src(str, ""))
      end
   end)
   it("rss", function()
      for f in vim.fs.dir "./spec/data/rss" do
         if not f:sub(0, 1) == "_" then -- TODO:
            local str = readfile(f, "./spec/data/rss/")
            check_feed_minimal(m.parse_src(str, ""))
         end
      end
   end)
   it("sanitize", function()
      for f in vim.fs.dir "./spec/data/sanitize" do
         if not f:sub(0, 1) == "_" then -- TODO:
            local str = readfile(f, "./spec/data/sanitize/") -- TODO: further check
            check_feed_minimal(m.parse_src(str, ""))
         end
      end
   end)
   it("xml", function()
      for f in vim.fs.dir "./spec/data/xml" do
         if not f:sub(0, 1) == "_" then -- TODO:
            local str = readfile(f, "./spec/data/xml/") -- TODO: further check
            check_feed_minimal(m.parse_src(str, ""))
         end
      end
   end)
end)

describe("reject encodings that neovim can not handle", function()
   local d = m.parse_src(readfile("encoding.xml", "./spec/data/"), "")
   eq("gb2312", d.encoding)
end)
