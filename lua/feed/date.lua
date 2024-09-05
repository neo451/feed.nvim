local M = {}
local config = require "feed.config"

---@alias feed.date osdate

local date = { __class = "date" }
date.__index = date

--- get absolute time value
function date:absolute()
   return os.time(self)
end

function date:from_now()
   return os.time() - os.time(self)
end

function date:__lt(other)
   return os.time(self) < os.time(other)
end

function date:__gt(other)
   return os.time(self) > os.time(other)
end

---@param format string
---@return string
function date:format(format)
   return os.date(format, os.time(self))
end

function date:__tostring()
   return self:format(config.layout.date.format)
end

---@param num integer
---@return feed.date
function date:days_ago(num)
   return M.new(os.date("*t", os.time(self) - num * 24 * 60 * 60))
end

---@param osdate osdate
---@return feed.date
function M.new(osdate)
   return setmetatable(osdate, date)
end

---@type feed.date
M.today = M.new(os.date "*t")

---@param str string
---@return feed.date
function M.new_from_str(str)
   local a, b, c = str:match "(%d+)-(%w+)-(%w+)"
   if not tonumber(b) then
      --- TODO: year(s) ago
      return M.today[b .. "_ago"](M.today, a)
   end
   return M.new { year = a, month = b, day = c }
end

---@param time integer
---@return feed.date
function M.new_from_int(time)
   return M.new(os.date("*t", time))
end

local patterns = {}
local months = { Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12 }
local weekdays = { Mon = 1, Tue = 2, Wed = 3, Thu = 4, Fri = 5, Sat = 6, Sun = 7 }

do
   local lpeg = vim.lpeg
   local C, P, S, R = lpeg.C, lpeg.P, lpeg.S, lpeg.R
   L = lpeg.locale()
   local ws = L.space
   local alpha = C(L.alpha ^ 1) / function(str)
      return months[str] and months[str] or weekdays[str]
   end
   local digit = C(L.digit ^ 1) / tonumber
   local col = P ":"
   local zone = (S "+-" * digit) + C(R "AZ" ^ 1)
   local min_and_sec = L.digit ^ 2 * P ":" * L.digit ^ 2 * P "-"
   patterns.RFC822 = alpha * P ", " * digit * ws * alpha * ws * digit * ws * digit * col * digit * col * digit * ws * zone
   -- patterns.RFC3339 = digit * P "-" * digit * P "-" * digit * S "Tt" * digit * ((R "09" + S "-:") ^ -7) * digit * P ":" * digit * R "AZ" ^ -1 -- ??
   patterns.RFC3339 = digit * P "-" * digit * P "-" * digit * S "Tt" * digit * (P ":" * min_and_sec ^ -1) * digit * P ":" * digit * (R "AZ" ^ -1) -- ??
end

--- [RSS spec] : All date-times in RSS conform to the Date and Time Specification of RFC 822, with the exception that the year may be expressed with two characters or four characters (four preferred).
---@param str string
---@return feed.date?
local function rfc822(str)
   local weekday, day, month, year, hour, min, sec, zone = patterns.RFC822:match(str)
   if not weekday then
      return nil
   end
   return M.new { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
end

---@param str string
---@return feed.date?
local function rfc3339(str)
   local year, month, day, hour, min, sec, patt_end = patterns.RFC3339:match(str)
   if not year then
      return nil
   end
   return M.new { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
end

M.new_from = {
   rss = rfc822,
   json = rfc3339,
}

---@param str string
---@return feed.date
---@return feed.date
function M.parse_date_filter(str)
   local sep = string.find(str, "%-%-")
   if not sep then
      str = string.sub(str, 2, #str)
      return { after = M.new_from_str(str) }, M.today
   else
      local start, stop = string.sub(str, 2, sep - 1), string.sub(str, sep + 2, #str)
      return M.new_from_str(start), M.new_from_str(stop)
   end
end

return M
