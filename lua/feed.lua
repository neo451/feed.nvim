local M = {}

---@param usr_config feed.config
M.setup = function(usr_config)
   local Config = require "feed.config"
   Config.resolve(usr_config)
   local cmds = require "feed.commands"
   cmds._sync_feedlist()
   for k, v in pairs(require "feed.commands") do
      if not k:sub(1, 1) == "_" then
         M[k] = v.impl
      end
   end

   local ui = require "feed.ui"
   M.get_entry = ui.get_entry
end


M.register_command = function(name, doc, context, f, key)
   local cmds = require "feed.commands"
   cmds[name] = {
      impl = f,
      doc = doc,
      context = context,
   }
   if key then
      local function map()
         local buf = vim.api.nvim_get_current_buf()
         vim.keymap.set("n", key, f, { silent = true, noremap = true, buffer = buf })
      end
      if context.all then
         vim.keymap.set("n", key, f, { silent = true, noremap = true })
      elseif context.index and context.entry then
         vim.api.nvim_create_autocmd("User", {
            pattern = { "FeedIndex", "FeedEntry" },
            callback = map,
         })
      elseif context.index then
         vim.api.nvim_create_autocmd("User", {
            pattern = "FeedIndex",
            callback = map,
         })
      elseif context.entry then
         vim.api.nvim_create_autocmd("User", {
            pattern = "FeedEntry",
            callback = map,
         })
      end
   end
end

return M
