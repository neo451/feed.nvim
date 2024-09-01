local M = require "rss.search"
local date = require "rss.date"

describe("parse_query", function()
   it("should split query into parts", function()
      local query = M.parse_query "+read -star =hello @5-days-ago"
      assert.same(
         { must_have = { "read" }, must_not_have = { "star" }, after = date.today:days_ago(5), before = date.today },
         query
      )
   end)
end)
