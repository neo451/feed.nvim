local M = require "feed.parser.date"
local eq = assert.equal

describe("new_from", function()
   it("should new from rfc3339", function()
      local res = M.rfc3339 "2010-02-07T14:04:00-05:00"
      eq("2010-02-07", tostring(res))
      res = M.rfc3339 "2024-09-02T16:58:40Z"
      eq("2024-09-02", tostring(res))
   end)
   it("should new from rfc2822", function()
      local res = M.rfc2822 "Tue, 10 Jun 2003 04:00:00 GMT"
      local res2 = M.rfc2822 "Tue, 10 Jun 2003 04:00:00 +0800"
      eq("2003-06-10", tostring(res))
      eq("2003-06-10", tostring(res2))
   end)
   it("should new from asctime", function()
      eq("2022-05-13", tostring(M.asctime "Fri May 13 2022 02:33:48 GMT+0800 (China Standard Time)"))
   end)
   it("should new from W3CDTF", function()
      eq("2024-09-13", tostring(M.W3CDTF "2024-09-13"))
      eq("2024-09-01", tostring(M.W3CDTF "2024-09"))
      eq("2024-01-01", tostring(M.W3CDTF "2024"))
   end)
end)

describe("format", function()
   it("should default to print with configed format", function()
      local res = M.rfc3339 "2010-02-07T14:04:00-05:00"
      eq("2010-02-07", res:format "%Y-%m-%d")
   end)
end)

describe("relative time func", function()
   it("should calculate days ago correctly", function()
      local today = M.today
      local days_ago_5 = today:days_ago(5)
      local expected_time = os.time(today) - (5 * 24 * 60 * 60)
      local expected_date = M.new(os.date("*t", expected_time))
      assert.are.same(expected_date, days_ago_5)
   end)

   it("should calculate months ago correctly", function()
      local today = M.today
      local months_ago_2 = today:months_ago(2)
      local expected_time = os.time(today)
      local expected_date = os.date("*t", expected_time)
      expected_date.month = expected_date.month - 2
      if expected_date.month <= 0 then
         expected_date.year = expected_date.year + math.floor((expected_date.month - 1) / 12)
         expected_date.month = expected_date.month % 12 + 12
      end
      expected_date = M.new(expected_date)
      assert.are.same(expected_date, months_ago_2)
   end)

   it("should calculate years ago correctly", function()
      local today = M.today
      local years_ago_3 = today:years_ago(3)
      local expected_time = os.time(today)
      local expected_date = os.date("*t", expected_time)
      expected_date.year = expected_date.year - 3
      expected_date = M.new(expected_date)
      assert.are.same(expected_date, years_ago_3)
   end)
end)
