local M = require "feed.parser"
local eq = MiniTest.expect.equality
local is_url = require("feed.utils").looks_like_url

local h = require "tests.helpers"
local readfile = h.readfile

local is_string = function(v)
   eq("string", type(v))
end

local is_table = function(v)
   eq("table", type(v))
end

local is_number = function(v)
   eq("number", type(v))
end

local check_feed = function(ast)
   is_string(ast.title, "no title")
   is_string(ast.desc, "not desc")
   is_url(ast.link)
   is_table(ast.entries)
   for _, v in ipairs(ast.entries) do
      if not v.link then
         vim.print(ast)
      end
      is_url(v.link, "no link")
      is_number(v.time, "no time")
      is_string(v.id, "no id")
      is_string(v.title, "no title")
      is_string(v.author, "no author")
      is_string(v.feed, "no feed")
   end
end

local check_feed_minimal = function(ast)
   -- assert.is_string(ast.title, "no title")
   is_string(ast.version)
   is_table(ast.entries)
end

local dump_date = function(time)
   return os.date("%Y-%m-%d", time)
end

local T = MiniTest.new_set()

T["rss"] = MiniTest.new_set {
   parametrize = {
      {
         "rss091.xml",
         { version = "rss091" },
      },
      {
         "rss092.xml",
         { version = "rss092" },
      },
      {
         "rss20.xml",
         { version = "rss20" },
      },
      {
         "rdf.xml",
         { version = "rss10" },
      },
      {
         "rdf/rss090_item_title.xml",
         { version = "rss090" },
      },
      {
         "rss_ns.xml",
         {
            version = "rss20",
            desc = "For documentation only",
            [1] = {
               time = "2002-09-04",
               author = "Mark Pilgrim (mark@example.org)",
            },
         },
      },
      {
         "rss_pod.xml",
         {
            version = "rss20",
            [1] = {
               author = "Kris Jenkins",
               link = "https://redirect.zencastr.com/r/episode/6723a17775cd3f17270161ed/size/105689812/audio-files/619e48a9649c44004c5a44e8/5af6e1e2-b4d9-4e98-8301-4b18f77ca296.mp3",
            },
         },
      },
      { "rss_atom.xml", { version = "rss20" } },
   },
}

T["json"] = MiniTest.new_set {
   parametrize = {
      { "json1", "json1" },
   },
}

T["atom"] = MiniTest.new_set {
   parametrize = {
      { "atom03.xml", { version = "atom03" } },
      { "atom10.xml", { version = "atom10" } },
      { "atom_html_content.xml", { version = "atom10" } },
   },
}

T["json"] = MiniTest.new_set {
   parametrize = {
      { "json1.json", { version = "json1" } },
      { "json2.json", { version = "json1" } },
   },
}

local function check(filename, checks)
   local f = M.parse_src(readfile(filename), "http://placehoder.feed")
   assert(f)
   for k, v in pairs(checks) do
      if type(v) == "table" then
         for kk, vv in pairs(v) do
            local res = f.entries[k][kk]
            if kk == "time" then
               eq(vv, dump_date(res)) -- TODO: move date_eq here
            else
               eq(vv, res)
            end
         end
      else
         eq(v, f[k])
      end
   end
   check_feed(f)
end

T["rss"]["works"] = check
T["atom"]["works"] = check
T["json"]["works"] = check

T["url resolover"] = MiniTest.new_set()

-- describe("url resolve", function()
--    it("resolve in atom, fallback to feed link?", function()
--       local src = [[
-- <?xml version="1.0" encoding="utf-8"?>
-- <feed version="0.3">
-- <title>Sample Feed</title>
-- <tagline>For documentation only</tagline>
-- <link rel="alternate" type="text/html" href="index.html"/>
-- <entry xml:base="http://example.org/archives/">
-- <title>First entry title</title>
-- <link rel="alternate" type="text/html" href="000001.html"/>
-- <author>
-- <name>Mark Pilgrim</name>
-- <url>../about/</url>
-- <email>mark@example.org</email>
-- </author>
-- </entry>
-- </feed>]]
--       local f = M.parse_src(src, "https://placehoder.feed")
--       eq(f.link, "https://placehoder.feed/index.html")
--       eq(f.entries[1].link, "http://example.org/archives/000001.html")
--
--       src = [[ <?xml version="1.0" encoding="utf-8"?>
-- <feed version="0.3" xml:base="https://example.org">
-- <title>Sample Feed</title>
-- <tagline>For documentation only</tagline>
-- <link rel="alternate" type="text/html" href="index.html"/>
-- <entry xml:base="http://example.org/archives/">
-- <title>First entry title</title>
-- <link rel="alternate" type="text/html" href="000001.html"/>
-- <author>
-- <name>Mark Pilgrim</name>
-- <url>../about/</url>
-- <email>mark@example.org</email>
-- </author>
-- </entry>
-- </feed>]]
--       f = M.parse_src(src, "https://placehoder.feed")
--       eq(f.link, "https://example.org/index.html")
--       eq(f.entries[1].link, "http://example.org/archives/000001.html")
--    end)
-- end)
--
--
--- TODO: parse the condition in the feed parser test suite, into a check table, and wemo check!!

-- describe("feedparser test suite", function()
--    it("atom", function()
--       for f in vim.fs.dir "./data/atom" do
--          local str = readfile(f, "./data/atom/")
--          check_feed_minimal(M.parse_src(str, ""))
--       end
--    end)
--    it("rss", function()
--       for f in vim.fs.dir "./data/rss" do
--          if not f:sub(0, 1) == "_" then -- TODO:
--             local str = readfile(f, "./data/rss/")
--             check_feed_minimal(M.parse_src(str, ""))
--          end
--       end
--    end)
--    it("sanitize", function()
--       for f in vim.fs.dir "./data/sanitize" do
--          -- if not f:sub(0, 1) == "_" then -- TODO:
--          local str = readfile(f, "./data/sanitize/") -- TODO: further check
--          check_feed_minimal(M.parse_src(str, ""))
--          -- end
--       end
--    end)
--    it("xml", function()
--       for f in vim.fs.dir "./data/xml" do
--          local str = readfile(f, "./data/xml/") -- TODO: further check
--          check_feed_minimal(M.parse_src(str, ""))
--       end
--    end)
--
--    -- it("rdf", function()
--    --    for f in vim.fs.dir "./data/rdf" do
--    --       local str = readfile(f, "./data/rdf/") -- TODO: further check
--    --       check_feed_minimal(m.parse_src(str, ""))
--    --    end
--    -- end)
-- end)
--
-- describe("reject encodings that neovim can not handle", function()
--    local d = M.parse_src(readfile("encoding.xml", "./data/"), "")
--    eq("gb2312", d.encoding)
-- end)
--
return T
