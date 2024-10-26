local m = require "feed.feedparser"
local eq = assert.are.same

vim.treesitter.language.add("html", {
   path = vim.fn.expand "~/.luarocks/lib/luarocks/rocks-5.1/tree-sitter-html/0.0.29-1/parser/html.so",
})

vim.treesitter.language.add("xml", {
   path = vim.fn.expand "~/.luarocks/lib/luarocks/rocks-5.1/tree-sitter-xml/0.0.29-1/parser/xml.so",
})

local sourced_file = require("plenary.debug_utils").sourced_filepath()
local data_dir = vim.fn.fnamemodify(sourced_file, ":h") .. "/data/"

local function readfile(path)
   local str = vim.fn.readfile(data_dir .. path)
   return table.concat(str)
end

local check_feed = function(ast, ispod)
   assert.is_string(ast.title)
   if not ispod then
      assert.is_string(ast.link)
   end
   assert.is_table(ast.entries)
   for _, v in ipairs(ast.entries) do
      assert.is_number(v.time)
      assert.is_string(v.id)
      assert.is_string(v.title)
      assert.is_string(v.author)
      assert.is_string(v.feed)
      assert.is_table(v.tags)
      assert.is_string(v.link)
   end
end

describe("rss", function()
   it("should reify to unified format", function()
      local str = readfile "rss_real_complex.xml"
      local ast = m.parse(str, "", { reify = true })
      check_feed(ast)

      -- str = readfile "rss_atom_tags.xml"
      -- local ast, t = m.parse(str, "", { reify = true })
      -- eq(t, "rss")
      -- check_feed(ast)
   end)
end)

describe("atom", function()
   it("should get ast", function()
      local str = readfile "atom_example.xml"
      local res = m.parse(str, nil, {})
      eq("http://www.w3.org/2005/Atom", res.xmlns)
   end)
   it("should reify to unified format", function()
      -- TODO: xhtml
      -- local str = readfile "atom_example.xml"
      -- local res = m.parse(str, "https://example.org")
      -- check_feed(res)

      str = readfile "atom_example2.xml"
      res = m.parse(str, "https://example.org")
      check_feed(res)
   end)
end)

describe("json", function()
   it("should get ast", function()
      local str = readfile "json_example.json"
      local res = m.parse(str, nil, {})
      eq("https://www.jsonfeed.org/feed.json", res.feed_url)
   end)
   it("should reify to unified format", function()
      local str = readfile "json_example.json"
      local ast = m.parse(str)
      check_feed(ast)
   end)
end)

local function readfile2(prefix, path)
   local f = io.open(prefix .. path, "r")
   local str
   if f then
      str = f:read "*a"
      f:close()
   end
   return str
end

local ts_c = 0
local nts_c = 0
local success = 0

local names = {}

local data_dir2 = vim.fn.fnamemodify(sourced_file, ":h") .. "/feed_data/"

local function test_dir(dir)
   for v in vim.fs.dir(dir) do
      local str = readfile2(dir, v)
      local ok, ast = pcall(m.parse, str, "https://neovim.io")
      if not ok then
         if ast:find "ts error" then
            ts_c = ts_c + 1
         else
            nts_c = nts_c + 1
            table.insert(names, v)
         end
      else
         success = success + 1
         check_feed(ast)
      end
   end
end

-- describe("simulation!", function()
--    it("should parse bunch of real world feeds", function()
--       test_dir(data_dir2)
--       print(("ts_error: %d; none-ts_error: %d; susccess: %d"):format(ts_c, nts_c, success))
--       print(vim.inspect(names))
--    end)
-- end)

describe("podcast enclosures", function()
   it("should parse enclosures", function()
      local str = readfile "podcast.xml"
      local ast = m.parse(str)
      check_feed(ast, true)
   end)
end)
