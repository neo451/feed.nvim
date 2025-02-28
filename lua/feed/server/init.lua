local uv = vim.uv
local ut = require("feed.utils")

-- TODO: get system dark mode

---@class feed.router
---@field routes { GET: table, POST: table, PUT: table, DELETE: table }
---@field middlewares function[]
---@field templates table<string, string>
local Router = {}
Router.__index = Router

function Router.new()
   local self = setmetatable({
      routes = { GET = {}, POST = {}, PUT = {}, DELETE = {} },
      middlewares = {},
      templates = {},
      handle = nil,
   }, Router)
   return self
end

function Router:add(method, path, handler)
   local pattern = path:gsub(":([%w_]+)", "([^/]+)")
   pattern = "^" .. pattern .. "$"

   self.routes[method][path] = {
      pattern = pattern,
      handler = handler,
   }
end

local function match_route(self, method, path)
   for _, route in pairs(self.routes[method]) do
      local matches = { path:match(route.pattern) }
      if #matches > 0 then
         return route.handler, matches
      end
   end
   return nil
end

function Router:get(path, handler)
   self:add("GET", path, handler)
end

function Router:use(middleware)
   table.insert(self.middlewares, middleware)
end

---@param name string
---@param temp string
function Router:template(name, temp)
   self.templates[name] = temp
end

function Router:render(name, context)
   local template = self.templates[name]
   for k, v in pairs(context or {}) do
      template = template:gsub("{{" .. k .. "}}", v)
   end
   return template
end

local function handle_request(self, req, res)
   for _, mw in ipairs(self.middlewares) do
      if not mw(req, res) then
         return
      end
   end

   local handler, params = match_route(self, req.method, req.path)

   if handler then
      req.params = params
      local ok, body = pcall(handler, req, res)

      if ok then
         res:send(body)
      else
         res:status(500):send("Internal Server Error")
      end
   else
      res:status(404):send("Not Found")
   end
end

local response = {
   status = function(self, code)
      self.statusCode = code
      return self
   end,
   send = function(self, body)
      local headers = {
         "Content-Type: text/html",
         "Content-Length: " .. #body,
         "Connection: close",
      }

      self.socket:write(
         "HTTP/1.1 " .. (self.statusCode or 200) .. " OK\r\n" .. table.concat(headers, "\r\n") .. "\r\n\r\n" .. body
      )
      self.socket:shutdown()
      self.socket:close()
   end,
}

function Router:listen(port)
   local handle = uv.new_tcp()
   assert(handle)
   assert(handle:bind("0.0.0.0", port))
   self.handle = handle
   handle:listen(128, function(err)
      local client = uv.new_tcp()
      assert(client)
      handle:accept(client)

      client:read_start(function(err, chunk)
         if err then
            client:close()
         end

         if chunk then
            local req = {
               method = chunk:match("(%u+) /"),
               path = chunk:match("%u+ (/[^%s]*)"),
               headers = {},
               body = chunk:match("\r\n\r\n(.*)"),
            }

            for line in chunk:gmatch("[^\r\n]+") do
               local k, v = line:match("(.-):%s*(.*)")
               if k then
                  req.headers[k:lower()] = v
               end
            end

            local res = {
               socket = client,
               req = req,
               statusCode = 200,
            }
            setmetatable(res, { __index = response })
            handle_request(self, req, res)
         end
      end)
   end)
   vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
         self.handle:close()
      end,
      desc = "Close HTTP server on Neovim exit",
   })
end

return {
   open = function(port)
      local router = Router.new()

      router:use(function(req, res)
         print(req.method .. " " .. req.path)
         return true
      end)

      local templates = vim.api.nvim_get_runtime_file("templates/*.html", true)

      for _, f in ipairs(templates) do
         local name = vim.fs.basename(f):sub(0, -6)
         router:template(name, ut.read_file(f))
      end

      local db = require("feed.db")
      local state = require("feed.ui.state")
      local Config = require("feed.config")

      if not state.entries then
         state.entries = db:filter(Config.search.default_query)
      end

      router:get("/", function(req, res)
         local acc = {}
         for _, id in ipairs(state.entries) do
            acc[#acc + 1] = router:render("entry", {
               id = id,
               title = db[id].title,
            })
         end

         return router:render("layout", {
            content = router:render("list", {
               query = vim.trim(state.query),
               docs = table.concat(acc),
               toggle = router:render("toggle"),
            }),
         })
      end)

      router:get("/documents/(%S+)", function(req, res)
         local id = req.params[1]
         local entry = db[id]

         local content = db:get(id)

         content = vim.trim(ut.unescape(content:gsub("\n", "")))

         if not content then
            return res:status(404):send("Non-exist Entry")
         end

         local feedUrl = entry.feed
         local feed = db.feeds[feedUrl]

         if feed then
            feed = ([[<a href="%s">%s</a>]]):format(feed.htmlUrl, feed.title)
         else
            feed = feedUrl
         end

         return router:render("layout", {
            content = router:render("document", {
               title = entry.title,
               author = entry.author,
               date = os.date(Config.date_format.long, entry.time),
               content = content,
               link = entry.link,
               feed = feed,
               toggle = router:render("toggle"),
            }),
         })
      end)

      router:listen(port)
   end,
}
