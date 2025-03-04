local Config = require("feed.config")

if Config.protocol.backend == "local" then
   return require("feed.db.local").new(Config.protocol["local"].dir)
elseif Config.protocol.backend == "ttrss" then
   return require("feed.db.ttrss").new()
end
