---@class feed.progress
---@field total integer
---@field count integer
---@field t integer
---@field progress vim.api.keyset.echo_opts
---@field finished boolean
local M = {}
M.__index = M

---@param count integer
---@param total integer
---@return integer
local function percentage(count, total)
   if total <= 0 then
      return 0
   end
   return math.min(100, math.max(0, math.floor(count / total * 100)))
end

M._percentage = percentage

function M.new(total)
   local ret = {}
   ret.total = math.max(0, math.floor(tonumber(total) or 0))
   ret.count = 0
   ret.finished = false
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
   if self.finished then
      return
   end
   self.finished = true
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
   if self.finished then
      return
   end
   vim.g.feed_progress = msg
   self.count = self.count + 1

   self.progress.status = "running"
   self.progress.percent = percentage(self.count, self.total)

   vim.schedule(function()
      self.progress.id = vim.api.nvim_echo({ { msg } }, true, self.progress)
   end)

   if self.total > 0 and self.count >= self.total then
      self:finish()
   end
end

return M
