local config = require "rss.config"
local fetch = require "rss.fetch"
local xml = require "rss.xml"

local cmds = {}

function cmds.load_opml(file)
   local feeds = xml.parse(file, { type = "opml" })[2].body.outline
   for _, feed in ipairs(feeds) do
      local title = feed.title
      local xmlUrl = feed.xmlUrl
      table.insert(config.feeds, { xmlUrl, name = title })
   end
end

function cmds.list_feeds()
   print(vim.inspect(vim.tbl_values(config.feeds)))
end

function cmds.update()
   -- print(#config.feeds)
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
