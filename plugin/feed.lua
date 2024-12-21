if 1 ~= vim.fn.has "nvim-0.10.0" then
   vim.api.nvim_err_writeln "feed.nvim requires at least nvim-0.10.0"
   return
end

if vim.g.loaded_feed == 1 then
   return
end
vim.g.loaded_feed = 1

local highlights = {
   FeedTitle = { default = true, link = "Title" },
   FeedLink = { default = true, link = "@markup.link.url" },
   FeedRead = { default = true, link = "@comment" },
   FeedTags = { default = true, link = "@punctuation.bracket" },
   FeedDate = { default = true, link = "function" },
   FeedBold = { default = true, link = "Bold" },
   FeedLabel = { default = true, link = "Label" },
}

for k, v in pairs(highlights) do
   vim.api.nvim_set_hl(0, k, v)
end

vim.api.nvim_create_user_command("Feed", function(opts)
   local cmds = require "feed.commands"

   if #opts.fargs == 0 then
      cmds._menu()
   else
      cmds._load_command(opts.fargs)
   end
end, {
   nargs = "*",
   complete = function(arg_lead, line)
      local cmds = require "feed.commands"
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
         local subcommand_keys = cmds._list_commands()
         return vim.iter(subcommand_keys)
             :filter(function(key)
                return key:find(arg_lead) ~= nil
             end)
             :totable()
      end
   end,
})
