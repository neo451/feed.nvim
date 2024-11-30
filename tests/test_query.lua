local M = require "feed.db.query"
local date = require "feed.parser.date"
local eq = MiniTest.expect.equality

describe("parse_query", function()
   it("should split query into parts", function()
      local query = M.parse_query "+read -star @5-days-ago linu[xs]"
      local expected = { must_have = { "read" }, must_not_have = { "star" }, after = date.days_ago(5), before = os.time(), re = { vim.regex "linu[xs]" } }
      eq(expected.must_have, query.must_have)
      eq(expected.must_not_have, query.must_not_have)
      eq(expected.after, query.after)
      eq(type(expected.re), type(query.re))
   end)
   it("should allow partial query for live searching", function()
      local query = M.parse_query "@6-"
      eq({}, query)
   end)
   it("should treat unread as negative read", function()
      local query = M.parse_query "+unread"
      eq("read", query.must_not_have[1])
      query = M.parse_query "-unread"
      eq("read", query.must_have[1])
   end)
end)
