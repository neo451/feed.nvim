local tests = {
   { "@5-days-ago--3-days-ago", 5, 3 },
   { "@3-days-ago--5-days-ago", 5, 3 },
   { "@2019-06-01", 23 },
   { "@2019-06-20--2019-06-01", 23, 4 },
   { "@2019-06-01--2019-06-20", 23, 4 },
   { "@2019-06-01--4-days-ago", 23, 4 },
   { "@4-days-ago--2019-06-01", 23, 4 },
}

package.path = package.path .. ";/home/n451/.local/share/nvim/lazy/plenary.nvim/lua/?.lua"
local M = require "feed.date"
local eq = assert.same

describe("new_from", function()
   it("should new from json", function()
      local res = M.new_from.json "2010-02-07T14:04:00-05:00"
      assert.same("2010-02-07", tostring(res))
      res = M.new_from.json "2024-09-02T16:58:40Z"
      eq("2024-09-02", tostring(res))
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
      assert.same("2010-02-07", res and res:format "%Y-%m-%d")
   end)
end)
