return function(url)
   if url:find("rsshub:/") then
      return url
   end
   local user, repo
   if url:find("github.com") and not url:find("news.txt") then
      user, repo = url:match("github.com/([^/]+)/([^/]+)")
   elseif url:find("^github:/") then
      user, repo = url:match("github://([^/]+)/([^/]+)")
   else
      user, repo = url:match("^([^/]+)/([^/]+)")
   end
   if not user or not repo then
      return url
   end
   local feedtype = "commits"
   if url:find("releases") then
      feedtype = "releases"
   end
   return ("https://github.com/%s/%s/%s.atom"):format(user, repo, feedtype)
end
