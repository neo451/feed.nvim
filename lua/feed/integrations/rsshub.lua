local Config = require("feed.config")
return function(url)
   return url:find("rsshub:/") and url:gsub("rsshub:/", Config.rsshub.instance) .. "?format=json?mode=fulltext" or url
end
