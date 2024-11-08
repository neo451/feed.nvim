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
      local ast, _, lastBuild = m.parse(str, "", nil, { reify = true })
      assert.equal("2024-09-04", lastBuild)
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
      local res = m.parse(str, nil, nil, {})
      eq("http://www.w3.org/2005/Atom", res.xmlns)
   end)
   it("should reify to unified format", function()
      -- TODO: xhtml
      -- local str = readfile "atom_example.xml"
      -- local res = m.parse(str, "https://example.org")
      -- check_feed(res)

      local str = readfile "atom_example2.xml"
      local res, _, lastBuild = m.parse(str, "https://example.org")
      eq("2024-09-29", lastBuild)
      check_feed(res)
   end)
end)

describe("json", function()
   it("should reify to unified format", function()
      local str = readfile "json_example.json"
      local ast, _, lastBuild = m.parse(str, "")
      check_feed(ast)
      eq("2020-08-07", lastBuild)
   end)
end)

describe("pod", function()
   it("should reify to unified format", function()
      local str = readfile "pod.xml"
      local ast = m.parse(str, "")
      check_feed(ast, true)
   end)
end)

describe("return", function()
   it("should return nil if lastBuild is same", function()
      local str = readfile "json_example.json"
      local ast = m.parse(str, "", "2020-08-07")
      assert.is_nil(ast)
   end)
end)
