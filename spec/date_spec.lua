-- local tests = {
--    { "@5-days-ago--3-days-ago", 5,  3 },
--    { "@3-days-ago--5-days-ago", 5,  3 },
--    { "@2019-06-01",             23 },
--    { "@2019-06-20--2019-06-01", 23, 4 },
--    { "@2019-06-01--2019-06-20", 23, 4 },
--    { "@2019-06-01--4-days-ago", 23, 4 },
--    { "@4-days-ago--2019-06-01", 23, 4 },
-- }

local M = require "feed.date"

describe("new_from", function()
   it("should new from json", function()
      local res = M.new_from.json "2010-02-07T14:04:00-05:00"
      local expected = tostring(res)
      assert.same("2010-02-07", expected)
      res = M.new_from.json "2024-09-02T16:58:40Z"
      assert.same("2024-09-02", tostring(res))
   end)
   it("should new from rss", function()
      local res = M.new_from.rss "Tue, 10 Jun 2003 04:00:00 GMT"
      local res2 = M.new_from.rss "Tue, 10 Jun 2003 04:00:00 +0800"
      assert.same("2003-06-10", tostring(res))
      assert.same("2003-06-10", tostring(res2))
   end)
end)

describe("format", function()
   it("should default to print with configed format", function()
      local res = M.new_from.json "2010-02-07T14:04:00-05:00"
      assert.same("1010-02-07", res:format "%Y-%m-%d")
   end)
end)
