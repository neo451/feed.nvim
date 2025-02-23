return function(url, instance)
   instance = instance or require("feed.config").rsshub.instance
   return url:find("rsshub:/") and url:gsub("rsshub:/", instance) .. "?format=json?mode=fulltext" or url
end
