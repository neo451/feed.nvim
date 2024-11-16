local M = require "feed.parser.opml"

vim.treesitter.language.add("xml", {
   path = vim.fn.expand "~/.luarocks/lib/luarocks/rocks-5.1/tree-sitter-xml/0.0.29-1/parser/xml.so",
})

describe("opml obj", function()
   it("should build a opml obj", function()
      local opml = M.import [[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>%s</title></head><body>
<outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
</body></opml>]]
      opml.xxx = { title = "world", text = "world", type = "atom", htmlUrl = "xxxxx" }
      assert.same(opml.xxx.type, "atom")
      assert.is_nil(opml.http.xmlUrl)
   end)

   it("should export to a file", function()
      local str = [[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>feed.nvim export</title></head><body>
<outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
<outline text="hello2" title="hello" type="rss" xmlUrl="http2" htmlUrl="https"/>
</body></opml>]]
      local feeds = M.import(str)
      local str2 = M.export(feeds)
      local feeds2 = M.import(str)
      assert.equal(str, str2)
      assert.same(feeds, feeds2)
   end)
end)

local sourced_file = require("plenary.debug_utils").sourced_filepath()
local data_dir = vim.fn.fnamemodify(sourced_file, ":h") .. "/data/"

local function readfile(path)
   local str = vim.fn.readfile(data_dir .. path)
   return table.concat(str)
end

describe("real", function()
   it("should import and export real opml", function()
      local str = readfile "opml_example.opml"
      local feeds = M.import(str)
      local str2 = M.export(feeds)
      local feeds2 = M.import(str2)
      assert.same(feeds, feeds2)
   end)
end)
