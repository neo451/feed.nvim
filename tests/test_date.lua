local M = require("feed.parser.date")
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

T["relative time"]["years ago"] = function()
   local res = M._years_ago(5, { year = 2025, month = 1, day = 2 })
   local expected = os.time { year = 2020, month = 1, day = 2 }
   date_eq(expected, res)
end

T["relative time"]["months ago"] = function()
   local res = M._months_ago(5, { year = 2025, month = 1, day = 2 })
   local expected = os.time { year = 2024, month = 8, day = 2 }
   date_eq(expected, res)
end

T["relative time"]["days ago"] = function()
   local res = M._days_ago(5, { year = 2025, month = 1, day = 2 })
   local expected = os.time { year = 2024, month = 12, day = 28 }
   date_eq(expected, res)
end

return T
