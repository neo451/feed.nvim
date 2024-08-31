local M = {}
---@class rss.date
---@field year number
---@field month number
---@field day number
---@field hour number
---@field min number
---@field sec number
---@field from_now fun():number
---@field absolute fun():number

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

function date:__tostring()
	return ("%d-%02d-%02d"):format(self.year, self.month, self.day)
end

function date:days_ago(num)
	return M.new(os.date("*t", os.time(self) - num * 24 * 60 * 60))
end

local months =
{ Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12 }

---@param osdate table
---@return rss.date
function M.new(osdate)
	return setmetatable(osdate, date)
end

---@type rss.date
M.today = M.new(os.date("*t"))

---@param str string
---@return rss.date
function M.new_from_str(str)
	local a, b, c = str:match("(%d+)-(%w+)-(%w+)")
	if not tonumber(b) then
		--- TODO: year(s) ago
		return M.today[b .. "_ago"](M.today, a)
	end
	return M.new({ year = a, month = b, day = c })
end

---@param time integer
---@return rss.date
function M.new_from_int(time)
	return M.new(os.date("*t", time))
end

---@param str string
---@return ... rss.date
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
