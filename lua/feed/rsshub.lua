local fetch = require("feed.fetch").fetch
local config = require "feed.config"

local function isFile(path)
   local f = io.open(path, "r")
   if f then
      f:close()
      return true
   end
   return false
end

local dir = vim.fn.expand(config.db_dir)

local function callback(res)
   local src = res.body
   local f = io.open(dir .. "/rsshub.json", "wb")
   -- print(f)
   if f then
      f:write(src)
      f:close()
   else
      print "failed to get rsshub.json"
   end
end

---generate rss feed from an instance name and route
---@param instance any
---@param route any
---@param params table<string, string>
local function gen_rss(instance, route, params)
   instance = instance or "rsshub.app"
   for k, v in pairs(params) do
      route = route:gsub(":" .. k, v)
   end
   return string.format("https://%s%s", instance, route)
end

local function fetch_radar()
   fetch("https://rsshub.app/api/radar/rules", 30000, callback)
end

---
---@return string
local function get_radar()
   local path = dir .. "/rsshub.json"
   local ret
   if isFile(path) then
      local f = io.open(path, "rb")
      if f then
         ret = f:read "*a"
         f:close()
      end
   end
   return vim.json.decode(ret)
end

local radar = get_radar()

-- pp(radar["telegram.org"])
local test = radar["diershoubing.com"]

---@param source any
local function process_source(source)
   local name = source._name
   local _, body = next(source)
   local route = body[1].target
   return name, route
end
local _, route = process_source(test)

local rss = gen_rss(nil, route, { category = "news" })

print(rss)

-- pp(get_radar())

-- radar()
