local M = require "feed.parser.date"
local eq = MiniTest.expect.equality

local date2string = function(n)
   local int = (type(n) == "number") and n or M.parse(n)
   return os.date("%Y-%m-%d", int)
end

local date_eq = MiniTest.new_expectation("date equality", function(left, right)
   return eq(date2string(left), date2string(right))
end, function(left, right)
   return ([[left: %s
right: %s]]):format(vim.inspect(left), vim.inspect(right))
end)

local T = MiniTest.new_set()

T["parse"] = MiniTest.new_set()
T["relative time"] = MiniTest.new_set()

T["parse"]["rfc3339"] = function()
   date_eq("2010-02-07", "2010-02-07T14:04:00-05:00")
   date_eq("2024-09-02", "2024-09-02T16:58:40Z")
end

T["parse"]["rfc2882"] = function()
   date_eq("2003-06-10", "Tue, 10 Jun 2003 04:00:00 GMT")
   date_eq("2003-06-10", "Tue, 10 Jun 2003 04:00:00 +0800")
end

T["parse"]["asctime"] = function()
   date_eq("2022-05-13", "Fri May 13 2022 02:33:48 GMT+0800 (China Standard Time)")
end

T["parse"]["W3CDTF"] = function()
   date_eq("2024-09-13", "2024-09-13")
   date_eq("2024-09-01", "2024-09")
   date_eq("2024-01-01", "2024")
end

local day = 24 * 60 * 60

T["relative time"]["days ago"] = function()
   local days_ago_5 = M.days_ago(5)
   local expected_time = os.time() - (5 * day)
   date_eq(expected_time, days_ago_5)
end

T["relative time"]["months ago"] = function()
   local months_ago_2 = M.months_ago(2)
   local expected_time = os.time()
   local expected_date = os.date("*t", expected_time)
   expected_date.month = expected_date.month - 2
   if expected_date.month <= 0 then
      expected_date.year = expected_date.year + math.floor((expected_date.month - 1) / 12)
      expected_date.month = expected_date.month % 12 + 12
   end
   date_eq(os.time(expected_date), months_ago_2)
end

T["relative time"]["year ago"] = function()
   local years_ago_3 = M.years_ago(3)
   local expected_time = os.time()
   local expected_date = os.date("*t", expected_time)
   expected_date.year = expected_date.year - 3
   eq(os.time(expected_date), years_ago_3)
end

return T
