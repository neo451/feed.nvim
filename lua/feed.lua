local M = {}
-- local ut = require "feed.ut"
-- local wrap = ut.wrap

local function wrap(f)
   return function()
      coroutine.wrap(f)()
   end
end

---@param usr_config feed.config
M.setup = function(usr_config)
   local config = require "feed.config"
   config.resolve(usr_config)
   local cmds = require "feed.commands"
   local render = require "feed.render"

   for k, v in pairs(cmds) do
      if type(v) == "table" then
         if v.context.all then
            vim.keymap.set("n", "<Plug>Feed_" .. k, wrap(v.impl), { noremap = true })
         else
            if v.context.index then
               vim.keymap.set("n", "<Plug>Feed_" .. k, wrap(v.impl), { noremap = true, buffer = render.buf.index })
            end
            if v.context.entry then
               vim.keymap.set("n", "<Plug>Feed_" .. k, wrap(v.impl), { noremap = true, buffer = render.buf.entry })
            end
         end
      end
   end
   vim.api.nvim_create_user_command("Feed", function(opts)
      ---@param args string[]
      local function load_command(args)
         local cmd = table.remove(args, 1)
         local item = cmds[cmd]
         if type(item) == "table" then
            coroutine.wrap(function()
               item.impl(unpack(args))
            end)()
         elseif type(item) == "function" then
            item(unpack(args))
         end
      end

      pcall(require("telescope").load_extension, "feed")
      pcall(require("telescope").load_extension, "feed_grep")

      if #opts.fargs == 0 then
         cmds()
         -- cmds.show_index()
      else
         load_command(opts.fargs)
      end
   end, {
      nargs = "*",
      complete = function(arg_lead, line)
         local subcmd_key, subcmd_arg_lead = line:match "^['<,'>]*Feed*%s(%S+)%s(.*)$"
         if subcmd_key and subcmd_arg_lead and cmds[subcmd_key] and type(cmds[subcmd_key]) == "table" and cmds[subcmd_key].complete then
            local sub_items = cmds[subcmd_key].complete()
            return vim.iter(sub_items)
               :filter(function(arg)
                  return arg:find(subcmd_arg_lead) ~= nil
               end)
               :totable()
         end
         if line:match "^['<,'>]*Feed*%s+%w*$" then
            -- Filter subcommands that match
            local subcommand_keys = vim.tbl_keys(cmds)
            return vim.iter(subcommand_keys)
               :filter(function(key)
                  return key:find(arg_lead) ~= nil
               end)
               :totable()
         end
      end,
   })
   M.index_buf = render.buf.index
   M.entry_buf = render.buf.entry
   M.get_entry = render.get_entry
end

setmetatable(M, {
   __index = function(self, k)
      if not rawget(self, k) then
         return rawget(require "feed.commands", k)
      end
   end,
})

return M
