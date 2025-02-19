local ut = require("feed.utils")
local backend = ut.choose_backend(require("feed.config").progress.backend)

local _, notify = pcall(require, "notify")
local _, MiniNotify = pcall(require, "mini.notify")
local spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }

-- FIX: nvim-notify subsitude

local function format_message(idx, total, message)
   return ("[%d/%d] %s"):format(idx, total, message)
end

local M = {}
M.__index = M

local backends = {
   fidget = {
      new = function(self, msg)
         local _, progress = pcall(require, "fidget.progress")
         self.handle = progress.handle.create({
            title = "Feed update",
            message = msg,
            percentage = 0,
         })
      end,
      update = function(self, msg)
         self.handle.percentage = self.handle.percentage + 100 / self.total
         self.handle.message = msg
      end,
      finish = function(self, msg)
         self.handle.message = msg
         self.handle:finish()
      end,
   },
   notify = {
      new = function(self, msg)
         self.id = notify(msg, nil, {
            hide_from_history = true,
            icon = spinner_frames[1],
            title = "Feed update",
         }).id
      end,
      update = function(self, msg)
         self.handle = notify(msg, nil, {
            hide_from_history = true,
            -- icon = spinner_frames[(self.count + 1) % #spinner_frames],
            replace = self.handle,
         })
      end,
      finish = function(self, msg)
         self.id = notify(msg, nil, {
            hide_from_history = true,
            icon = "",
            replace = self.id,
         }).id
      end,
   },
   mini = {
      new = function(self, msg)
         self.id = MiniNotify.add(msg, "INFO", "Title")
      end,
      update = function(self, msg)
         MiniNotify.update(self.id, { msg = msg })
      end,
      finish = function(self, msg)
         MiniNotify.remove(self.id)
         local opts = { INFO = { duration = 1000 } }
         MiniNotify.make_notify(opts)(msg)
      end,
   },
   snacks = {
      new = function(_, msg)
         Snacks.notifier.notify(msg, "info", { id = "feed" })
      end,
      update = function(_, msg)
         Snacks.notifier.notify(msg, "info", { id = "feed" })
      end,
      finish = function(_, msg)
         Snacks.notifier.notify(msg, "info", { id = "feed" })
      end,
   },
   native = {
      new = function(_, msg)
         vim.schedule_wrap(vim.notify)(msg, 2, { id = "feed" })
      end,
      update = function(_, msg)
         vim.schedule_wrap(vim.notify)(msg, 2, { id = "feed" })
      end,
      finish = function(_, msg)
         vim.schedule_wrap(vim.notify)(msg, 2, { id = "feed" })
      end,
   },
   winbar = {},
}

function M.new(total)
   local ret = {}
   local starting_message = "Start fetching.."
   backends[backend].new(ret, starting_message)
   ret.total = total
   ret.count = 0
   ret.t = os.time()
   return setmetatable(ret, M)
end

local function finish(self)
   local msg = ("Fetched update in %ds"):format(os.time() - self.t)
   backends[backend].finish(self, msg)
end

function M:update(message)
   self.count = self.count + 1
   local msg = format_message(self.count, self.total, message)
   backends[backend].update(self, msg)
   if self.count == self.total then
      finish(self)
   end
end

return M
