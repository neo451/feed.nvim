local M = require "feed.parser.init"
local eq = MiniTest.expect.equality

local h = require "tests.helpers"
local readfile = h.readfile
local is_url = h.is_url

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
   is_string(ast.title)
   is_string(ast.desc)
   is_url(ast.link)
   is_table(ast.entries)
   for _, v in ipairs(ast.entries) do
      if not v.link then
         vim.print(ast)
      end
      is_url(v.link)
      is_number(v.time)
      is_string(v.title)
      is_string(v.author)
      is_string(v.feed)
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
      { "atom03.xml",            { version = "atom03" } },
      { "atom10.xml",            { version = "atom10" } },
      { "atom_html_content.xml", { version = "atom10" } },
      { "reddit.xml",            { version = "atom10" } },
   },
}

T["json"] = MiniTest.new_set {
   parametrize = {
      { "json1.json", { version = "json1" } },
      { "json2.json", { version = "json1" } },
   },
}

T["url resolover"] = MiniTest.new_set {
   parametrize = {
      {
         "url_atom.xml",
         {
            link = "http://placehoder.feed/index.html",
            [1] = {
               link = "http://example.org/archives/000001.html",
            },
         },
      },

      {
         "url_atom2.xml",
         {
            link = "http://example.org/index.html",
            [1] = {
               link = "http://example.org/archives/000001.html",
            },
         },
      },

      {
         "url_rss.xml",
         {
            link = "http://example.org",
            [1] = {
               link = "http://example.org/archives/000001.html",
            },
         },
      }
   },
}

local function check(filename, checks)
   local f = M.parse(readfile(filename), "http://placehoder.feed")
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
T["url resolover"]["works"] = check
--
--- TODO: parse the condition in the feed parser test suite, into a check table, and wemo check!!

T["feedparser test suite"] = MiniTest.new_set {
   parametrize = {
      { "/data/atom" },
      { "/data/rss" },
      { "/data/sanitize" },
      { "/data/xml" },
      { "/data/rdf" },
      -- { "/data/itunes" },
   },
}

local function check_suite(dir)
   for f in vim.fs.dir(dir) do
      local str = readfile(f, dir)
      check_feed_minimal(M.parse(str, ""))
   end
end

T["feedparser test suite"]["works"] = check_suite

-- describe("reject encodings that neovim can not handle", function()
--    local d = M.parse(readfile("encoding.xml", "./data/"), "")
--    eq("gb2312", d.encoding)
-- end)
--
return T
