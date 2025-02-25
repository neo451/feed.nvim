local Config = require("feed.config")

if Config.protocol.backend == "local" then
   return require("feed.db.local")
elseif Config.protocol.backend == "ttrss" then
   return require("feed.db.ttrss")
end
