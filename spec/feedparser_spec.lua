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
   assert.not_nil(ast.title)
   assert.not_nil(ast.link)
   assert.not_nil(ast.entries)
   for _, v in ipairs(ast.entries) do
      -- print(v.time)
      -- print(v.id)
      -- print(v.title)
      -- print(v.feed)
      -- print(v.tags)
      -- print(v.link)
      -- print(v.author)
      assert.not_nil(v.time)
      assert.not_nil(v.id)
      assert.not_nil(v.title)
      assert.not_nil(v.feed)
      assert.not_nil(v.tags)
      assert.not_nil(v.link)
      assert.not_nil(v.author)
   end
end

describe("rss", function()
   it("should get ast", function()
      local str = readfile "rss_example_2.0.xml"
      local res = m.parse(str, { type = "rss" })
      eq("2.0", res.version)
      res = m.parse(str)
      eq("2.0", res.version)

      str = readfile "rss_example_0.92.xml"
      res = m.parse(str)
      eq("0.92", res.version)

      str = readfile "rss_example_0.91.xml"
      res = m.parse(str)
      eq("0.91", res.version)

      str = readfile "rss_real_zh_cdata.xml"
      res = m.parse(str)
      eq("2.0", res.version)

      str = readfile "rss_real_complex.xml"
      res = m.parse(str)
      eq("2.0", res.version)
   end)
   it("should reify to unified format", function()
      local str = readfile "rss_real_complex.xml"
      local ast = m.parse(str, { reify = true })
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
      local str = readfile "atom_example.xml"
      local res = m.parse(str, { reify = true })
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
