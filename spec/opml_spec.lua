local M = require "feed.opml"

vim.treesitter.language.add("xml", {
   path = vim.fn.expand "~/.luarocks/lib/luarocks/rocks-5.1/tree-sitter-xml/0.0.29-1/parser/xml.so",
})

local sourced_file = require("plenary.debug_utils").sourced_filepath()
local data_dir = vim.fn.fnamemodify(sourced_file, ":h") .. "/data/"

local opml_path = data_dir .. "feeds.opml"

describe("opml obj", function()
   it("should build a opml obj", function()
      local opml = M.import [[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>%s</title></head><body>
<outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
</body></opml>]]
      opml:append { title = "world", text = "world", type = "atom", xmlUrl = "xxx", htmlUrl = "xxxxx" }
      opml:append { title = "world", text = "world", type = "atom", xmlUrl = "xxx", htmlUrl = "xxxxx" }
      assert.same(opml.outline[2].type, "atom")
      assert.is_nil(opml.outline[3]) -- Avoids dup items
   end)

   it("should build a opml obj and exclude invalid entries", function()
      local opml = M.import [[<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0"><head><title>%s</title></head><body>
<outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
<outline text="hello" title="hello" type="rss" htmlUrl="https"/>
</body></opml>]]
      opml:append { title = "world", text = "world", type = "atom", xmlUrl = "xxx", htmlUrl = "xxxxx" }
      opml:append { title = "world", text = "world", type = "atom", htmlUrl = "yyyyyy" }
      assert.same(opml.outline[2].type, "atom")
      assert.is_nil(opml.outline[3]) -- Avoids dup items
   end)

   it("should pprint a opml obj", function()
      local opml = M.import [[<?xml version="1.0" encoding="UTF-8"?>
   <opml version="1.0"><head><title>test opml</title></head><body>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   </body></opml>]]
      assert.same(tostring(opml), "<OPML>name: test opml, size: 5")
   end)
   it("should export to a file", function()
      local opml = M.import [[<?xml version="1.0" encoding="UTF-8"?>
   <opml version="1.0"><head><title>test opml</title></head><body>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   <outline text="hello" title="hello" type="rss" xmlUrl="http" htmlUrl="https"/>
   </body></opml>]]
      opml:export(opml_path)
      local str = vim.fn.readfile(opml_path)
      local new_opml = M.import(table.concat(str))
      assert.is_table(new_opml)
   end)
end)

local function readfile(path)
   local str = vim.fn.readfile(data_dir .. path)
   return table.concat(str)
end

describe("real opml data", function()
   it("should from podcast app export", function()
      local str = readfile "xiaoyuzhou.opml"
      local res = M.import(str)
      assert.same("Xiaoyuzhou Podcast Collection", res.title)
      assert.same("https://feed.xyzfm.space/ub4ld7umvgjr", res.outline[#res.outline].xmlUrl)
   end)
end)
