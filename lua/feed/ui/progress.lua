local ut = require("feed.utils")
local backend = ut.choose_backend(require("feed.config").progress.backend)

local _, MiniNotify = pcall(require, "mini.notify")

local function format_message(idx, total, message)
   return ("[%d/%d] %s"):format(idx, total, message)
end

local M = {}
M.__index = M

local backends = {
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

function M.extend(name, class)
   backends[name] = class
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

function mini:new(msg)
   self.id = MiniNotify.add(msg, "INFO", "Title")
end

function mini:update(msg)
   pcall(MiniNotify.update, self.id, { msg = msg })
end

function mini:finish(msg)
   MiniNotify.remove(self.id)
   local opts = { INFO = { duration = 1000 } }
   MiniNotify.make_notify(opts)(msg)
end

local snacks = {}

function snacks:new(msg)
   Snacks.notifier.notify(msg, "info", { id = "feed" })
end

function snacks:update(msg)
   Snacks.notifier.notify(msg, "info", { id = "feed" })
end

function snacks:finish(msg)
   Snacks.notifier.notify(msg, "info", { id = "feed" })
end

local native = {}

function native:new(msg)
   vim.schedule_wrap(vim.notify)(msg, 2, { id = "feed" })
end

function native:update(_, msg)
   vim.schedule_wrap(vim.notify)(msg, 2, { id = "feed" })
end

function native:finsih(_, msg)
   vim.schedule_wrap(vim.notify)(msg, 2, { id = "feed" })
end

M.extend("fidget", fidget)
M.extend("mini", mini)
M.extend("snacks", snacks)
M.extend("native", native)

return M
