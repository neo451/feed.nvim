local config = require("feed.config")
local _, MiniNotify = pcall(require, "mini.notify")
local _, SnacksNotifier = pcall(require, "snacks.notify")
local SnacksNotify
if SnacksNotifier then
   SnacksNotify = SnacksNotifier.notify
end

---@class feed.progress
---@field total integer
---@field count integer
---@field t integer
---@field update fun(self: feed.progress, message: string)
---@field finish function
---@field new function
---@field backend feed.progress
local M = {}
M.__index = M

local backends = setmetatable({}, {
   __index = function()
      return {
         new = function() end,
         update = function() end,
         finish = function() end,
      }
   end,
})

function M.new(total)
   local ret = {}
   ret.total = total
   ret.count = 0
   ret.t = os.time()
   ret.backend = backends[config.progress.backend]
   ret.backend:new()
   ret.__index = ret
   setmetatable(ret.backend, ret)
   return setmetatable(ret, M)
end

function M:finish()
   local msg = ("Fetched update in %ds"):format(os.time() - self.t)
   self.backend:finish(msg)
   vim.g.feed_progress = msg
   vim.defer_fn(function()
      vim.g.feed_progress = nil
   end, 2000)
end

function M:update(msg)
   vim.g.feed_progress = msg
   self.count = self.count + 1
   self.backend:update(msg)
end

local fidget = {}

function fidget:new(msg)
   local _, progress = pcall(require, "fidget.progress")
   self.handle = progress.handle.create({
      title = "Feed update",
      message = msg,
      percentage = 0,
   })
end

function fidget:update(msg)
   self.handle.percentage = self.handle.percentage + 100 / self.total
   self.handle.message = msg
end

function fidget:finish(msg)
   self.handle.message = msg
   self.handle:finish()
end

local mini = {}

function mini:new() end

function mini:update(msg)
   if not self.id then
      self.id = MiniNotify.add(msg, "INFO", "Title")
   else
      MiniNotify.update(self.id, { msg = msg })
   end
end

function mini:finish(msg)
   MiniNotify.remove(self.id)
   self.id = nil
   local opts = { INFO = { duration = 1000 } }
   MiniNotify.make_notify(opts)(msg)
end

local snacks = {}

function snacks:new() end

function snacks:update(msg)
   SnacksNotify(msg, { id = "feed" })
end

function snacks:finish(msg)
   SnacksNotify(msg, { id = "feed" })
end

backends.fidget = fidget
backends.snacks = snacks
backends.mini = mini

return M
