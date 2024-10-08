local M = require "feed.opml"

vim.treesitter.language.add("xml", {
   path = vim.fn.expand "~/.luarocks/lib/luarocks/rocks-5.1/tree-sitter-xml/0.0.29-1/parser/xml.so",
})

local sourced_file = require("plenary.debug_utils").sourced_filepath()
local data_dir = vim.fn.fnamemodify(sourced_file, ":h") .. "/data/"

describe("opml obj", function()
   it("should build a opml obj", function()
      local opml = M.import(data_dir .. "opml_example.opml")
      opml:export(data_dir .. "exported_opml.opml")
      assert.are_string(opml:export())
      local exported_opml = M.import(data_dir .. "exported_opml.opml")
      assert.same(opml.title, exported_opml.title)
      assert.same(opml.outline, exported_opml.outline)
   end)
   it("should build a opml obj", function()
      local opml = M.import_s [[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>%s</title></head><body>
<outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
</body></opml>]]
      opml:append { text = "world", type = "atom", xmlUrl = "xxx", htmlUrl = "xxxxx" }
      opml:append { text = "world", type = "atom", xmlUrl = "xxx", htmlUrl = "xxxxx" }
      assert.same(opml.outline[2].type, "atom")
      assert.is_nil(opml.outline[3]) -- Avoids dup items
   end)

   it("should pprint a opml obj", function()
      local opml = M.import_s [[<?xml version="1.0" encoding="UTF-8"?>
   <opml version="1.0"><head><title>test opml</title></head><body>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   </body></opml>]]
      assert.same(tostring(opml), "<OPML>name: test opml, size: 5")
   end)
end)
