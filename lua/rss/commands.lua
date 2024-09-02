local config = require "rss.config"
local fetch = require "rss.fetch"
local opml = require "rss.opml"

local cmds = {}

function cmds.load_opml(file)
   local feeds = opml.parse_opml(file)
   for _, feed in ipairs(feeds) do
      local item = feed
      local title = item.title
      local xmlUrl = item.xmlUrl
      config.feeds[title] = xmlUrl
   end
end

function cmds.list_feeds()
   print(vim.inspect(vim.tbl_values(config.feeds)))
end

function cmds.update()
   for i, link in ipairs(config.feeds) do
      fetch.update_feed(link, #config.feeds, i)
   end
end

---@param args string[]
local function load_command(args)
   local cmd = table.remove(args, 1)
   return cmds[cmd](unpack(args))
end

---TODO:
-- function autocmds.update_feed(name)
-- 	fetch.update_feed(config.feeds[name], name, 1, 1)
-- end
return {
   load_command = load_command,
   cmds = cmds,
}

-- vim.api.nvim_create_autocmd("VimLeavePre", {
--    pattern = "*.md",
--    callback = function()
--       print "leave!"
--       db:save()
--       -- autocmds.update()
--    end,
-- })
