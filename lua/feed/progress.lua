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
local _, MiniNotify = pcall(require, "mini.notify") -- TODO:

local function update_fidget(handle, total, name)
   if handle.percentage == 100 then
      handle.percentage = 0
      handle.count = 0
   end
   if not handle.count then
      handle.count = 0
   end
   handle.count = handle.count + 1
   handle.percentage = handle.percentage + 100 / total
   handle.message = "got " .. name
   if handle.count == total then
      handle:finish()
   end
end

local spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }

local function notify_new()
   local notif_data = { spinner = 0 }
   notif_data.notification = notify("Fetching feeds", nil, {
      hide_from_history = true,
      icon = spinner_frames[1],
      title = "Feed update",
   })
   return notif_data
end

local fidget_new = function()
   local _, progress = pcall(require, "fidget.progress")
   local handle = progress.handle.create {
      title = "Feed update",
      message = "fetching feeds...",
      percentage = 0,
   }
   return handle
end

local function finish_notify(obj)
   obj.notification = notify("Fetched all feeds", nil, {
      hide_from_history = true,
      icon = "",
      replace = obj.notification,
   })
   obj.spinner = 0
end

local function format_message(idx, total, message)
   return ("[%d/%d] got %s"):format(idx, total, message)
end

local function update_notify(obj, total, message)
   obj.spinner = obj.spinner + 1

   obj.notification = notify(format_message(obj.spinner, total, message), nil, {
      hide_from_history = false,
      icon = spinner_frames[(obj.spinner + 1) % #spinner_frames],
      replace = obj.notification,
   })
   if obj.spinner == total then
      return finish_notify(obj)
   end
end

local function new()
   if backend == "fidget" then
      return fidget_new()
   elseif backend == "notify" then
      return notify_new()
   elseif backend == "mini" then
      return { id = MiniNotify.add("0", "INFO", "Title"), c = 0 }
   elseif backend == "native" then
      return { c = 0 }
   end
end

local function update_native(handle, total, message)
   handle.c = handle.c + 1
   print(("[%d/%d] got %s"):format(handle.c, total, message))
   if handle.c == total then
      print "Feed fetch finished"
   end
end

local function update_mini(handle, total, message)
   handle.c = handle.c + 1
   MiniNotify.update(handle.id, { msg = ("[%d/%d] got %s"):format(handle.c, total, message) })
   if handle.c == total then
      MiniNotify.remove(handle.id)
      local opts = { INFO = { duration = 1000 } }
      MiniNotify.make_notify(opts) "Feed fetch finished"
   end
end

local handle = nil

local function advance(total, message)
   if not handle then
      handle = new()
   end
   if backend == "fidget" then
      update_fidget(handle, total, message)
   elseif backend == "notify" then
      update_notify(handle, total, message)
   elseif backend == "mini" then
      update_mini(handle, total, message)
   elseif backend == "native" then
      update_native(handle, total, message)
   end
end

return {
   advance = advance,
}
