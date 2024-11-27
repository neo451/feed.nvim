local function choose_backend()
   local config = require "feed.config"
   if type(config.progress) == "string" then
      return config.progress
   end
   for _, v in ipairs(config.progress) do
      local ok = pcall(require, v)
      if ok then
         return v
      end
   end
end

local backend = choose_backend()

local _, notify = pcall(require, "notify")
local _, mini = pcall(require, "mini.notify")
local spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }

local function format_message(idx, total, message)
   return ("[%d/%d] %s"):format(idx, total, message)
end

local mt = {}
mt.__index = mt

function mt.new(total)
   local ret = {}
   if backend == "fidget" then
      local _, progress = pcall(require, "fidget.progress")
      ret.handle = progress.handle.create {
         title = "Feed update",
         message = "fetching feeds...",
         percentage = 0,
      }
   elseif backend == "notify" then
      ret.handle = notify("Fetching feeds", nil, {
         hide_from_history = true,
         icon = spinner_frames[1],
         title = "Feed update",
      })
   elseif backend == "mini" then
      ret.id = mini.add("0", "INFO", "Title")
   end
   ret.total = total
   ret.count = 0
   ret.t = os.time()
   return setmetatable(ret, mt)
end

local function finish(self)
   local msg = ("Fetched update in %ds"):format(os.time() - self.t)
   if backend == "fidget" then
      self.handle.message = msg
      self.handle:finish()
   elseif backend == "notify" then
      self.handle = notify(msg, nil, {
         hide_from_history = true,
         icon = "",
         replace = self.handle,
      })
   elseif backend == "mini" then
      mini.remove(self.id)
      local opts = { INFO = { duration = 1000 } }
      mini.make_notify(opts)(msg)
   elseif backend == "native" then
      print(msg)
   end
end

function mt:update(message)
   self.count = self.count + 1
   local msg = format_message(self.count, self.total, message)
   if backend == "fidget" then
      self.handle.percentage = self.handle.percentage + 100 / self.total
      self.handle.message = msg
   elseif backend == "notify" then
      self.handle = notify(msg, nil, {
         hide_from_history = false,
         icon = spinner_frames[(self.count + 1) % #spinner_frames],
         replace = self.handle,
      })
   elseif backend == "mini" then
      mini.update(self.id, { msg = msg })
   else
      print(msg)
   end
   if self.count == self.total then
      finish(self)
   end
end

return mt
