local config = require "feed.config"

local date = { __class = "date" }
date.__index = date

--- get absolute time value
---@return integer
function date:absolute()
   return os.time(self)
end

---@return integer
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
   return self:format("%Y-%m-%d" or config.date_format)
end

---@param num integer
---@return feed.date
function date:days_ago(num)
   local new = vim.deepcopy(date.today, true)
   new.day = new.day - num
   return new
end

function date:years_ago(num)
   local new = vim.deepcopy(date.today, true)
   new.year = new.year - num
   return new
end

function date:months_ago(num)
   local new = vim.deepcopy(date.today, true)
   new.month = new.month - num
   return new
end

date.day_ago = date.days_ago
date.year_ago = date.years_ago
date.month_ago = date.months_ago

---@param osdate table
---@return feed.date
function date.new(osdate)
   return setmetatable(osdate, date)
end

---@type feed.date
date.today = date.new(os.date "*t")

---@param str string
---@return feed.date
local function parse_date(str)
   local a, b, c = str:match "(%d+)-(%w+)-(%w+)"
   if not tonumber(b) then
      return date.today[b .. "_ago"](date.today, a)
   end
   return date.new { year = a, month = b, day = c }
end

---@param str string
---@return feed.date
---@return feed.date?
local function parse_date_filter(str)
   local sep = string.find(str, "%-%-")
   if not sep then
      str = string.sub(str, 2, #str)
      return parse_date(str):absolute(), nil
   else
      local start, stop = string.sub(str, 2, sep - 1), string.sub(str, sep + 2, #str)
      return parse_date(start):absolute(), parse_date(stop):absolute()
   end
end

---@param time integer
---@return feed.date
local function int_to_date(time)
   return date.new(os.date("*t", time))
end

local patterns = {}
local months = { Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12 }
local weekdays = { Mon = 1, Tue = 2, Wed = 3, Thu = 4, Fri = 5, Sat = 6, Sun = 7 }

do
   local lpeg = vim.lpeg
   local C, P, S, R = lpeg.C, lpeg.P, lpeg.S, lpeg.R
   local L = lpeg.locale()
   local ws = L.space
   local alpha = C(L.alpha ^ 1) / function(str)
      return months[str] and months[str] or weekdays[str]
   end
   local digit = C(L.digit ^ 1) / tonumber
   local col = P ":"
   local zone = (S "+-" * digit) + C(R "AZ" ^ 1)
   local min_and_sec = L.digit ^ 2 * P ":" * L.digit ^ 2 * P "-"
   patterns.RFC2822 = alpha * P ", " * digit * ws * alpha * ws * digit * ws * digit * col * digit * col * digit * ws * zone
   patterns.RFC3339 = digit * P "-" * digit * P "-" * digit * S "Tt" * digit * (P ":" * min_and_sec ^ -1) * digit * (P ":" ^ -1) * (digit ^ -1) * (R "AZ" ^ -1)
end

--- [RSS spec] : All date-times in RSS conform to the Date and Time Specification of RFC 2822, with the exception that the year may be expressed with two characters or four characters (four preferred).
---@param str string
---@return feed.date?
local function rfc2822(str)
   local weekday, day, month, year, hour, min, sec, _ = patterns.RFC2822:match(str) -- TODO: handle zone?
   if not weekday then
      return nil
   end
   return date.new { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
end

---@param str string
---@return feed.date?
local function rfc3339(str)
   local year, month, day, hour, min, sec, _ = patterns.RFC3339:match(str)
   if not year then
      return nil
   end
   return date.new { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
end

date.new_from = {
   rss = function(str)
      if not str then
         return os.time()
      end
      local time = rfc2822(str)
      if not time then
         time = rfc3339(str) -- some rss feeds have atom timetags...
      end
      if time then
         return time:absolute()
      else
         return os.time()
      end
   end,
   json = function(str)
      if not str then
         return os.time()
      end
      local time = rfc3339(str)
      if time then
         return time:absolute()
      else
         return os.time()
      end
   end,
   atom = function(str)
      if not str then
         return os.time()
      end
      local time = rfc3339(str)
      if time then
         return time:absolute()
      else
         return os.time()
      end
   end,
   filter = parse_date_filter,
   number = int_to_date,
   rfc3339 = rfc3339,
   rfc2822 = rfc2822,
}

return date
