---@class feed.progress
---@field total integer
---@field count integer
---@field t integer
---@field progress vim.api.keyset.echo_opts
local M = {}
M.__index = M

function M.new(total)
   local ret = {}
   ret.total = total
   ret.count = 0
   ret.t = os.time()
   ret.progress = {
      kind = "progress",
      status = "running",
      percent = 0,
      title = "feed.nvim update",
      source = "feed.nvim",
   }
   return setmetatable(ret, M)
end

function M:finish()
   local msg = ("Fetched update in %ds"):format(os.time() - self.t)
   vim.g.feed_progress = msg
   self.progress.status = "success"
   self.progress.percent = 100
   vim.schedule(function()
      vim.api.nvim_echo({ { msg } }, true, self.progress)
   end)
   vim.defer_fn(function()
      vim.g.feed_progress = nil
   end, 2000)
end

function M:update(msg)
   vim.g.feed_progress = msg
   self.count = self.count + 1

   self.progress.status = "running"
   self.progress.percent = math.floor(self.count / self.total * 100)

   vim.schedule(function()
      self.progress.id = vim.api.nvim_echo({ { msg } }, true, self.progress)
   end)

   if self.count == self.total then
      self:finish()
   end
end

return M
