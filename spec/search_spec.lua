local M = require "feed.search"
local date = require "feed.date"

describe("parse_query", function()
   it("should split query into parts", function()
      local query = M.parse_query "+read -star =hello @5-days-ago"
      local expected = { must_have = { "read" }, must_not_have = { "star" }, after = date.today:days_ago(5), before = date.today }
      assert.same(expected.must_have, query.must_have)
      assert.same(expected.must_not_have, query.must_not_have)
      assert.same(expected.after, query.after)
      assert.same(expected.before, query.before)
   end)
end)

describe("filter", function()
   it("filter by tags", function()
      local query = M.parse_query "+unread -star"
      local index = {
         { tags = { unread = true, star = true }, v = 1 },
         { tags = { unread = true }, v = 2 },
         { tags = { star = true }, v = 3 },
         { tags = {}, v = 4 },
         { tags = { unread = true }, v = 2 },
      }
      local res, map = M.filter(index, query)
      assert.same({ index[2], index[5] }, res)
      assert.same({ [1] = 2, [2] = 5 }, map)
   end)
end)
