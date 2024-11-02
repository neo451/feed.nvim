local M = require "feed.search"
local date = require "feed.date"

describe("parse_query", function()
   it("should split query into parts", function()
      local query = M.parse_query "+read -star @5-days-ago linu[xs]"
      local expected =
         { must_have = { "read" }, must_not_have = { "star" }, after = date.today:days_ago(5):absolute(), before = date.today:absolute(), re = { vim.regex "linu[xs]" } }
      assert.same(expected.must_have, query.must_have)
      assert.same(expected.must_not_have, query.must_not_have)
      assert.same(expected.after, query.after)
      assert.same(expected.before, query.before)
      assert.same(type(expected.re), type(query.re))
   end)
end)

describe("filter", function()
   it("return identical if query empty", function()
      local index = {
         { tags = { unread = true, star = true }, time = 1 },
      }
      local res = M.filter(index, {})
      assert.same(index, res)
   end)

   it("filter by tags", function()
      local query = M.parse_query "+unread -star"
      local index = {
         { tags = { unread = true, star = true }, time = 1 },
         { tags = { unread = true }, time = 2 },
         { tags = { star = true }, time = 3 },
         { tags = {}, time = 4 },
         { tags = { unread = true }, time = 2 },
      }
      local res = M.filter(index, query)
      assert.same({ index[2], index[5] }, res)
   end)

   it("filter by date", function()
      local query = M.parse_query "@5-days-ago"
      local index = {
         { time = date.today:days_ago(6):absolute(), v = 6 },
         { time = date.today:days_ago(7):absolute(), v = 7 },
         { time = date.today:days_ago(1):absolute(), v = 1 },
         { time = date.today:absolute(), v = 0 },
      }
      local res = M.filter(index, query)
      assert.same({ index[4], index[3] }, res)
   end)

   it("filter by regex", function()
      local query = M.parse_query "Neo vim"
      local index = {
         { title = "Neovim is awesome", time = 1 },
         { title = "neovim is lowercase", time = 1 },
         { title = "Vim is awesome", time = 1 },
         { title = "vim is lowercase", time = 1 },
         { title = "bim is not a thing", time = 1 },
      }
      local res = M.filter(index, query)
      assert.same({ index[1], index[2] }, res)
   end)

   it("filter by limit number", function()
      local query = M.parse_query "#10"
      local entries = {}
      for i = 1, 20 do
         entries[i] = { title = i, time = i }
      end
      local res = M.filter(entries, query)
      assert.same(10, #res)
   end)
end)
