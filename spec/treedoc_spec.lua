-- local src = [[
-- <!DOCTYPE html>
-- <h1>hello</h1>
-- <p>world <code>zig</code> is awesome</p>
-- <code class="language-zig" b="c">const x: u8 = 42;</code>
-- <a href="https://ziglang.org">ziglang</a>
-- ]]

-- local src = [[
-- <ol>
--    <li>one</li>
--    <li>two</li>
--    <li>three</li>
-- </ol>
-- ]]
local M = require "rss.treedoc"
-- describe("acutual rss feed", function()
--    it("should produce simple lua table", function()
local sourced_file = require("plenary.debug_utils").sourced_filepath()
local data_dir = vim.fn.fnamemodify(sourced_file, ":h:h") .. "/data/"
local str = vim.fn.readfile(data_dir .. "rss_example_2.0.xml")
str = table.concat(str)
local ast = M.parse(str, { language = "xml" })
pp(ast)
-- M.parse([[<rss version="0.92">]], { language = "xml" })
-- pp(M.parse([[<rss version="0.92">2.0<chan><title>test</title></chan></rss>]], { language = "xml" }))
