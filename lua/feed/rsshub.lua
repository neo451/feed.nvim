local fetch = require("feed.fetch").fetch
local config = require "feed.config"

local path = require "plenary.path"

local radar = {
   dir = path:new(config.db_dir .. "/rsshub.json"):expand(),
}

function radar:open()
   local radar_handle = path:new(self.dir)
   if not radar_handle:is_file() then
      radar_handle:touch()
   end
   return radar_handle
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

function radar:fetch()
   local function callback(res)
      local src = res.body
      local f = radar:open()
      f:write(src, "w")
   end
   fetch("https://rsshub.app/api/radar/rules", 30000, callback)
end

-- ---@param source any
-- local function process_source(source)
--    local name = source._name
--    local _, body = next(source)
--    local route = body[1].target
--    return name, route
-- end
--
-- local get_rss_feed = function(url)
--    local obj = radar:open()[url]
--    local name, route = process_source(obj)
--    return gen_rss(nil, route, { category = "news" })
-- end

-- print(get_rss_feed "diershoubing.com")

-- pp(get_radar())

-- radar()
