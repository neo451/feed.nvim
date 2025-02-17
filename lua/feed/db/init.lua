local Config = require("feed.config")

if Config.data.backend == "local" then
   return require("feed.db.local")
elseif Config.data.backend == "ttrss" then
   return require("feed.db.ttrss")
end
