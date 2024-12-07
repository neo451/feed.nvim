local M = {}

---@param num integer
---@return integer
---@private
function M.days_ago(num)
   local new_time = os.time() - (num * 24 * 60 * 60)
   return new_time
end

---@param num integer
---@return integer
---@private
function M.years_ago(num)
   local new_time = os.time()
   local new_date = os.date("*t", new_time)
   new_date.year = new_date.year - num
   return os.time(new_date)
end

---@param num integer
---@return integer
---@private
function M.months_ago(num)
   local new_date = os.date("*t", os.time())
   new_date.month = new_date.month - num
   if new_date.month <= 0 then
      new_date.year = new_date.year + math.floor((new_date.month - 1) / 12)
      new_date.month = new_date.month % 12 + 12
   end
   return os.time(new_date)
end

M.day_ago = M.days_ago
M.year_ago = M.years_ago
M.month_ago = M.months_ago

---@param str string
---@return integer?
local function filter_part(str)
   local a, b, c = unpack(vim.split(str, "-"))
   if not a then
      return
   end
   if b and not tonumber(b) then
      if b:find "day" then
         return M.days_ago(tonumber(a))
      elseif b:find "month" then
         return M.months_ago(tonumber(a))
      elseif b:find "year" then
         return M.months_ago(tonumber(a))
      else
         return
      end
   end
   local year, month, day = tonumber(a), tonumber(b) or 1, tonumber(c) or 1
   if not year then
      return
   end
   return os.time { year = year, month = month, day = day }
end

---@param str string
---@return integer?
---@return integer?
function M.parse_filter(str)
   local sep = string.find(str, "%-%-")
   if not sep then
      str = string.sub(str, 2, #str)
      return filter_part(str), nil
   else
      local start, stop = string.sub(str, 2, sep - 1), string.sub(str, sep + 2, #str)
      return filter_part(start), filter_part(stop)
   end
end

local patterns = {}
local months = { Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12 }
local weekdays = { Sun = 1, Mon = 2, Tue = 3, Wed = 4, Thu = 5, Fri = 6, Sat = 7 }

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
   patterns.ASCTIME = alpha * ws * alpha * ws * digit * ws * digit * ws * digit * col * digit * col * digit * ws -- TODO: zone
end

---@param str string
---@return integer?
local function asctime(str)
   local weekday, month, day, year, hour, min, sec, _ = patterns.ASCTIME:match(str)
   if not weekday then
      return nil
   end
   return os.time { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
end

---@param str string
---@return integer?
local function rfc2822(str)
   local weekday, day, month, year, hour, min, sec, _ = patterns.RFC2822:match(str)
   if not weekday then
      return nil
   end
   return os.time { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
end

---@param str string
---@return integer?
local function rfc3339(str)
   local year, month, day, hour, min, sec, _ = patterns.RFC3339:match(str)
   if not year then
      return nil
   end
   return os.time { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
end

---@param str string
---@return integer?
local function W3CDTF(str)
   local a, b, c = unpack(vim.split(str, "-"))
   if not a then
      return
   end
   return os.time { year = tonumber(a), month = tonumber(b) or 1, day = tonumber(c) or 1 }
end

local order = {
   "rfc3339",
   "rfc2822",
   "asctime",
   "W3CDTF",
}

M.rfc2822 = rfc2822
M.rfc3339 = rfc3339
M.W3CDTF = W3CDTF
M.asctime = asctime

---@param t string
---@param feed_type feed.type
---@return integer
M.parse = function(t, feed_type)
   if not t then
      return os.time()
   end
   local time
   if feed_type == "json" then
      return rfc3339(t) or os.time()
   else
      for _, p in ipairs(order) do
         time = M[p](t)
         if time then
            return time
         end
      end
      return os.time()
   end
end

return M
