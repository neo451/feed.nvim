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
