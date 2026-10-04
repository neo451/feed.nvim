local Curl = require("feed.curl")
local db = require("feed.db")
local fetch = require("feed.fetch")
local parser = require("feed.parser")
local eq = MiniTest.expect.equality

local original_curl_get = Curl.get
local original_update_feed = fetch.update_feed
local original_feeds = db.feeds
local original_vim_system = vim.system

local T = MiniTest.new_set({
   hooks = {
      post_case = function()
         Curl.get = original_curl_get
         fetch.update_feed = original_update_feed
         db.feeds = original_feeds
         vim.system = original_vim_system
      end,
   },
})

local function mock_system(response)
   vim.system = function(cmd, _, on_exit)
      for i, arg in ipairs(cmd) do
         if arg == "-D" then
            local file = assert(io.open(cmd[i + 1], "w"))
            file:write("HTTP/1.1 200 OK\r\ncontent-type: application/xml\r\n\r\n")
            file:close()
            break
         end
      end

      local handle = {
         wait = function()
            return response
         end,
      }
      if on_exit then
         on_exit(response)
      end
      return handle
   end
end

T["curl supports synchronous waits"] = function()
   mock_system({ code = 0, stdout = "body" })
   local response = Curl.get("https://example.com/feed", {}):wait()

   eq(200, response.status)
   eq("body", response.stdout)
end

T["curl uses error-first callbacks"] = function()
   mock_system({ code = 0, stdout = "body" })
   local callback_err
   local response
   Curl.get("https://example.com/feed", {}, function(err, value)
      callback_err = err
      response = value
   end)

   eq(
      true,
      vim.wait(1000, function()
         return response ~= nil
      end)
   )
   eq(nil, callback_err)
   eq(200, response.status)
end

T["parser returns the request handle and response"] = function()
   local handle = {}
   local response = { status = 304 }
   Curl.get = function(_, _, cb)
      cb(nil, response)
      cb("duplicate callback", nil)
      return handle
   end

   local calls = 0
   local result
   local returned = parser.parse("https://example.com/feed", {}, function(err, value)
      eq(nil, err)
      calls = calls + 1
      result = value
   end)

   eq(handle, returned)
   eq(response, result)
   eq(1, calls)
end

T["parser propagates request errors"] = function()
   Curl.get = function(_, _, cb)
      cb("request failed", nil)
      return {}
   end

   local callback_err
   parser.parse("https://example.com/feed", {}, function(err)
      callback_err = err
   end)

   eq("request failed", callback_err)
end

T["update waits for every feed regardless of completion order"] = function()
   db.feeds = {
      ["https://example.com/a"] = { title = "a" },
      ["https://example.com/b"] = { title = "b" },
   }

   local callbacks = {}
   fetch.update_feed = function(url, _, cb)
      callbacks[url] = cb
      return { url = url }
   end

   local completions = 0
   local callback_err
   local handles = fetch.update(function(err)
      completions = completions + 1
      callback_err = err
   end)

   eq(2, #handles)
   callbacks["https://example.com/b"](nil, true)
   callbacks["https://example.com/b"]("duplicate callback", false)
   eq(0, completions)
   callbacks["https://example.com/a"]("failed", false)
   eq(1, completions)
   eq("failed", callback_err)
end

T["empty update completes without starting requests"] = function()
   db.feeds = {}
   local calls = 0
   fetch.update_feed = function()
      error("unexpected update")
   end

   local handles = fetch.update(function(err)
      eq(nil, err)
      calls = calls + 1
   end)

   eq({}, handles)
   eq(1, calls)
end

return T
