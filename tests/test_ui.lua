local config = require("feed.config")
config.protocol["local"].dir = "~/.feed.nvim.test"

local db = require("feed.db")
local eq = MiniTest.expect.equality
local h = dofile("tests/helpers.lua")
local M = require("feed.ui")

-- local function new_db()
--    db:blowup()
--    db = db.new("~/.feed.nvim.test/")
-- end

T = MiniTest.new_set({})

T["opml load/export"] = function()
   M.load_opml("./data/opml_web.xml")
   db:update()
   eq(false, vim.tbl_isempty(db.feeds))
   -- HACK:
   -- eq(238, vim.tbl_count(db.feeds))
   M.export_opml("./data/export_opml")
   local export = vim.fs.find({ "export_opml" }, { path = "./data" })[1]
   assert(export)
   M.load_opml("./data/export_opml")
   -- eq(238, vim.tbl_count(db.feeds))
   eq(false, vim.tbl_isempty(db.feeds))
   vim.fn.delete(export)
end

-- TODO: list, hints

-- T["winbar"] = function()
--    -- local child = MiniTest.new_child_neovim()
--    --
--    -- child.restart({ '-u', 'scripts/minimal_init.lua' })
--    -- child.lua [[M = require"feed.ui"]]
--    -- child.lua [[M.show_winbar()]]
--
--    -- local expected =
--    -- [[ %#FeedDate#%-11{g:feed_date}%#FeedTitle#%-26{g:feed_feed}%#FeedTags#%-16{g:feed_tags}%#FeedTitle#%-1{g:feed_title}%=%#FeedDate#%1{g:feed_last_updated}%#FeedLabel#%1{g:feed_query}]]
--    -- eq(expected, M.show_winbar())
--    -- eq(expected, child.lua_get 'vim.wo.winbar')
--
--    -- TODO: screen shot
-- end

-- T['update_feed'] = function()
--    M.update_feed.impl("https://neovim.io/news.xml")
-- end

return T
