local M = require "feed.opml"

vim.treesitter.language.add("xml", {
   path = vim.fn.expand "~/.local/share/nvim/lazy/nvim-treesitter/parser/xml.so",
})

describe("opml obj", function()
   it("should build a opml obj", function()
      local opml = M.import "~/Plugins/feed.nvim/spec/data/opml_example.opml"
      opml:export "/home/n451/Plugins/feed.nvim/exported_opml.opml"
      assert.are_string(opml:export())
      local exported_opml = M.import "/home/n451/Plugins/feed.nvim/exported_opml.opml"
      assert.same(opml.title, exported_opml.title)
      assert.same(opml.outline, exported_opml.outline)
   end)
   it("should build a opml obj", function()
      local opml = M.import_s [[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>%s</title></head><body>
<outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
</body></opml>]]
      opml:append("world", "atom", "xxx", "xxxxx")
      assert.same(opml.outline[2].type, "atom")
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
