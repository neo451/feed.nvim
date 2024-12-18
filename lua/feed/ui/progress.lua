local ut = require "feed.utils"
local backend = ut.choose_backend(require("feed.config").progress.backend)

local _, notify = pcall(require, "notify")
local _, MiniNotify = pcall(require, "mini.notify")
local spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }

-- FIX: nvim-notify subsitude
--

local function format_message(idx, total, message)
   return ("[%d/%d] %s"):format(idx, total, message)
end

local mt = {}
mt.__index = mt

function mt.new(total)
   local ret = {}
   local starting_message = "Start fetching.."
   if backend == "fidget" then
      local _, progress = pcall(require, "fidget.progress")
      ret.handle = progress.handle.create {
         title = "Feed update",
         message = starting_message,
         percentage = 0,
      }
   elseif backend == "notify" then
      ret.id = notify(starting_message, nil, {
         hide_from_history = true,
         icon = spinner_frames[1],
         title = "Feed update",
      }).id
   elseif backend == "mini" then
      ret.id = MiniNotify.add(starting_message, "INFO", "Title")
   elseif backend == "snacks" then
      Snacks.notifier.notify(starting_message, "info", { id = "feed" })
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
      self.id = notify(msg, nil, {
         hide_from_history = true,
         icon = "",
         replace = self.id,
      }).id
   elseif backend == "mini" then
      MiniNotify.remove(self.id)
      local opts = { INFO = { duration = 1000 } }
      MiniNotify.make_notify(opts)(msg)
   elseif backend == "snacks" then
      Snacks.notifier.notify(msg, "info", { id = "feed" })
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
         hide_from_history = true,
         -- icon = spinner_frames[(self.count + 1) % #spinner_frames],
         replace = self.handle
      })
   elseif backend == "mini" then
      MiniNotify.update(self.id, { msg = msg })
   elseif backend == "snacks" then
      Snacks.notifier.notify(msg, "info", { id = "feed" })
   else
      print(msg)
   end
   if self.count == self.total then
      finish(self)
   end
end

return mt
