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
