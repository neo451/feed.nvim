package.path = package.path .. ";/home/n451/.local/share/nvim/lazy/plenary.nvim/lua/?.lua"

local m = require "feed.feedparser"
local eq = assert.are.same

vim.treesitter.language.add("html", {
   path = vim.fn.expand "~/.local/share/nvim/lazy/nvim-treesitter/parser/html.so",
})

vim.treesitter.language.add("xml", {
   path = vim.fn.expand "~/.local/share/nvim/lazy/nvim-treesitter/parser/xml.so",
})

local sourced_file = require("plenary.debug_utils").sourced_filepath()
local data_dir = vim.fn.fnamemodify(sourced_file, ":h") .. "/data/"

local function readfile(path)
   local str = vim.fn.readfile(data_dir .. path)
   return table.concat(str)
end

local check_feed = function(ast)
   assert.is_string(ast.title)
   assert.is_string(ast.link)
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
   it("should get ast", function()
      local str = readfile "rss_example_2.0.xml"
      local res = m.parse(str, { reify = false })
      eq("2.0", res.version)

      str = readfile "rss_example_0.92.xml"
      res = m.parse(str, { reify = false })
      eq("0.92", res.version)

      str = readfile "rss_example_0.91.xml"
      res = m.parse(str, { reify = false })
      eq("0.91", res.version)

      str = readfile "rss_real_zh_cdata.xml"
      res = m.parse(str, { reify = false })
      eq("2.0", res.version)

      str = readfile "rss_real_complex.xml"
      res = m.parse(str, { reify = false })
      eq("2.0", res.version)

      str = readfile "rss_atom_tags.xml"
      res = m.parse(str, { reify = false })
      eq("2.0", res.version)
   end)

   it("should reify to unified format", function()
      local str = readfile "rss_real_complex.xml"
      local ast = m.parse(str, { reify = true })
      check_feed(ast)

      str = readfile "rss_atom_tags.xml"
      ast, t = m.parse(str, { reify = true })
      eq(t, "rss")
      check_feed(ast)
   end)
end)

describe("atom", function()
   it("should get ast", function()
      local str = readfile "atom_example.xml"
      local res = m.parse(str, { type = "atom" })
      eq("http://www.w3.org/2005/Atom", res.xmlns)
   end)
   it("should reify to unified format", function()
      -- TODO: xhtml
      local str = readfile "atom_example.xml"
      local res = m.parse(str, { reify = true }, "https://example.org")
      check_feed(res)

      local str = readfile "atom_example2.xml"
      local res = m.parse(str, { reify = true }, "https://example.org")
      check_feed(res)
   end)
end)

describe("json", function()
   it("should get ast", function()
      local str = readfile "json_example.json"
      local res = m.parse(str, { type = "json" })
      eq("https://www.jsonfeed.org/feed.json", res.feed_url)
   end)
   it("should reify to unified format", function()
      local str = readfile "json_example.json"
      local ast = m.parse(str, { reify = true })
      check_feed(ast)
   end)
end)
