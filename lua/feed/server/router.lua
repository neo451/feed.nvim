local uv = vim.uv

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

function Router:post(path, handler)
   self:add("POST", path, handler)
end

function Router:use(middleware)
   table.insert(self.middlewares, middleware)
end

---@param name string
---@param temp string
function Router:template(name, temp)
   self.templates[name] = temp
end

function Router:render(name, context, on_rendered)
   local template = self.templates[name]
   for k, v in pairs(context or {}) do
      local ok
      ok, template = pcall(string.gsub, template, "{{" .. k .. "}}", function()
         return v
      end)
      if not ok then
         error("Error rendering template: " .. k .. v)
      end
   end

   if on_rendered then
      on_rendered()
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
         res:status(500):send("Internal Server Error: " .. body)
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
         "Content-Type: text/html; charset=UTF-8",
         "Content-Length: " .. (body and #body or 0),
         "Connection: close",
      }

      self.socket:write(
         "HTTP/1.1 "
            .. (self.statusCode or 200)
            .. " OK\r\n"
            .. table.concat(headers, "\r\n")
            .. "\r\n\r\n"
            .. (body or "")
      )
      self.socket:shutdown()
      self.socket:close()
   end,
}

function Router:listen(port)
   local handle = uv.new_tcp()
   assert(handle, "failed to spawn tcp handle")
   assert(handle:bind("0.0.0.0", port), "failed to bind to port")
   self.handle = handle
   handle:listen(128, function(err)
      local client = uv.new_tcp()
      assert(client, "failed to spawn client")
      handle:accept(client)

      client:read_start(function(_, chunk)
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

return Router
