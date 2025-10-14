local Router = require("feed.server.router")
local ut = require("feed.utils")
local db = require("feed.db")
local state = require("feed.state")
local config = require("feed.config")

local router = Router.new()

local render_entries = function()
   local acc = {}
   for _, id in ipairs(state.entries) do
      acc[#acc + 1] = router:render("headline", {
         id = id,
         title = db[id].title,
      })
   end
   return table.concat(acc)
end

if vim.g.feed_debug then
   router:use(function(req, _)
      print(req.method .. " " .. req.path)
      return true
   end)
end

local M = {}
M.open = function(query, port)
   state.query = query or state.query
   local templates = vim.api.nvim_get_runtime_file("templates/*.html", true)

   for _, f in ipairs(templates) do
      local name = vim.fs.basename(f):sub(0, -6)
      router:template(name, ut.read_file(f))
   end

   router:get("/", function(_, _)
      state.entries = db:filter(state.query)
      return router:render("layout", {
         content = router:render("list", {
            query = vim.trim(state.query),
            docs = render_entries(),
            toggle = router:render("toggle"),
         }),
      })
   end)

   router:get("/entry/(%S+)", function(req, res)
      local id = req.params[1]
      local entry = db[id]

      local content = db:get(id)

      if not content then
         return res:status(404):send("Non-exist Entry")
      end

      local feedUrl = entry.feed
      local feed = db.feeds[feedUrl]
      assert(feed, "failed to retrive feed") -- TODO: reflect in page?
      local feed_string

      if feed then
         feed_string = ([[<a href="%s">%s</a>]]):format(feed.htmlUrl, feed.title)
      else
         feed_string = feedUrl
      end

      return router:render("layout", {
         content = router:render("document", {
            title = entry.title,
            author = entry.author or feed.title,
            date = os.date(config.date.format.long, entry.time),
            content = content,
            link = entry.link,
            feed = feed_string,
            toggle = router:render("toggle"),
         }),
      }, function()
         db:tag(id, "read")
      end)
   end)

   router:post("/search", function(req, _)
      local q = req.body:match("search=(.*)")
      q = vim.uri_decode(q)
      state.query = q
      state.entries = db:filter(q)
      return render_entries()
   end)

   router:listen(port)
end

return M
