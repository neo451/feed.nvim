local M = {}

---@param usr_config feed.config
M.setup = function(usr_config)
   local config = require "feed.config"
   config.resolve(usr_config)
   vim.api.nvim_create_user_command("Feed", function(opts)
      local cmds = require "feed.commands"

      ---@param args string[]
      local function load_command(args)
         local cmd = table.remove(args, 1)
         if type(cmds[cmd]) == "table" then
            return cmds[cmd].impl(unpack(args))
         elseif type(cmds[cmd]) == "function" then
            return cmds[cmd](unpack(args))
         end
      end

      pcall(require("telescope").load_extension, "feed")
      pcall(require("telescope").load_extension, "feed_grep")

      if #opts.fargs == 0 then
         cmds.show_index()
      else
         load_command(opts.fargs)
      end
   end, {
      nargs = "*",
      complete = function(arg_lead, line)
         local cmds = require "feed.commands"
         local subcmd_key, subcmd_arg_lead = line:match "^['<,'>]*Feed*%s(%S+)%s(.*)$"
         if subcmd_key and subcmd_arg_lead and cmds[subcmd_key] and type(cmds[subcmd_key]) == "table" and cmds[subcmd_key].complete then
            return cmds[subcmd_key].complete(subcmd_arg_lead)
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
end
--
-- setmetatable(M, {
--    __index = function(self, k)
--       if not rawget(self, k) then
--          return rawget(require "feed.commands", k)
--       end
--    end,
-- })
--
return M
