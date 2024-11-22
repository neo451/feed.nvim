local M = {}

---@param usr_config feed.config
M.setup = function(usr_config)
   local config = require "feed.config"
   config.resolve(usr_config)
   local cmds = require "feed.commands"
   cmds._sync_feedlist()
end

local render = require "feed.render"
M.get_entry = render.get_entry

M.register_command = function(name, doc, context, f, key)
   local ut = require "feed.utils"
   local cmds = require "feed.commands"
   cmds[name] = {
      impl = f,
      doc = doc,
      context = context,
   }
   if key then
      if context["all"] then
         vim.keymap.set("n", key, ut.wrap(f))
      end
      if context["index"] then
         if render.index then
            vim.keymap.set("n", key, ut.wrap(f), { buffer = render.index })
         end
      end
      if context["entry"] then
         if render.entry then
            vim.keymap.set("n", key, ut.wrap(f), { buffer = render.entry }) -- TODO:??
         end
      end
   end
end

return M
