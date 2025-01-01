local M = {}

---@param num integer
---@return integer
---@private
local function days_ago(num)
   return os.time() - (num * 24 * 60 * 60)
end

---@param num integer
---@return integer
---@private
local function years_ago(num)
   local new_time = os.time()
   local new_date = os.date("*t", new_time)
   new_date.year = new_date.year - num
   ---@diagnostic disable-next-line: param-type-mismatch
   return os.time(new_date)
end

---@param n integer
---@return integer
---@private
local function months_ago(n)
   -- Get the current date
   local now = os.date("*t")

   -- Calculate the new month and year
   local year = now.year
   local month = now.month - n

   while month <= 0 do
      month = month + 12
      year = year - 1
   end

   -- Keep the day the same, but ensure the new month is valid
   local day = now.day
   local days_in_new_month = os.date("*t", os.time { year = year, month = month + 1, day = 0 }).day
   if day > days_in_new_month then
      day = days_in_new_month
   end

   return os.time { year = year, month = month, day = day }
end

local patterns = {}
local months =
{ Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12 }
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
   local col = P(":")
   local zone = (S("+-") * digit) + C(R("AZ") ^ 1)
   local min_and_sec = L.digit ^ 2 * P(":") * L.digit ^ 2 * P("-")
   patterns.RFC2822 = alpha
       * P(", ")
       * digit
       * ws
       * alpha
       * ws
       * digit
       * ws
       * digit
       * col
       * digit
       * col
       * digit
       * ws
       * zone
   patterns.RFC3339 = digit
       * P("-")
       * digit
       * P("-")
       * digit
       * S("Tt")
       * digit
       * (P(":") * min_and_sec ^ -1)
       * digit
       * (P(":") ^ -1)
       * (digit ^ -1)
       * (R("AZ") ^ -1)
   patterns.ASCTIME = alpha * ws * alpha * ws * digit * ws * digit * ws * digit * col * digit * col * digit *
       ws -- TODO: zone
end

---@param str string
---@return integer?
local function asctime(str)
   local weekday, month, day, year, hour, min, sec, _ = patterns.ASCTIME:match(str)
   if not weekday then
      return nil
   end
   return os.time({ year = year, month = month, day = day, hour = hour, min = min, sec = sec })
end

---@param str string
---@return integer?
local function rfc2822(str)
   local weekday, day, month, year, hour, min, sec, _ = patterns.RFC2822:match(str)
   if not weekday then
      return nil
   end
   return os.time({ year = year, month = month, day = day, hour = hour, min = min, sec = sec })
end

---@param str string
---@return integer?
local function rfc3339(str)
   local year, month, day, hour, min, sec, _ = patterns.RFC3339:match(str)
   if not year then
      return nil
   end
   return os.time({ year = year, month = month, day = day, hour = hour, min = min, sec = sec })
end

---@param str string
---@return integer?
local function W3CDTF(str)
   local a, b, c = unpack(vim.split(str, "-"))
   if not a then
      return
   end
   return os.time({ year = tonumber(a) or 1, month = tonumber(b) or 1, day = tonumber(c) or 1 })
end

local order = {
   rfc3339,
   rfc2822,
   asctime,
   W3CDTF,
}

---@param str string
---@param t feed.type
---@return integer
M.parse = function(str, t)
   if str then
      if t == "json" then
         local time = rfc3339(str)
         if time then
            return time
         end
      else
         for _, f in ipairs(order) do
            local time = f(str)
            if time then
               return time
            end
         end
      end
   end
   return os.time()
end

function M.literal(str)
   local a, unit, ago = unpack(vim.split(str, "-"))
   local n = tonumber(a)
   if n and unit and ago then
      if unit:find("day") then
         return days_ago(n)
      elseif unit:find("month") then
         return months_ago(n)
      elseif unit:find("year") then
         return years_ago(n)
      end
   end
end

---@param str string
---@return integer?
local function numeral(str)
   local a, b, c = unpack(vim.split(str, "-"))
   if a and b and c then
      return os.time({ year = tonumber(a), month = tonumber(b), day = tonumber(c) })
   end
end

---@param str string
---@return integer?
local function filter_part(str)
   for _, f in ipairs({ M.literal, numeral }) do
      if f(str) then
         return f(str)
      end
   end
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

return M
