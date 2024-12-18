local eq = MiniTest.expect.equality

local config = require("feed.config")
config.db_dir = "~/.feed.nvim.test/"
config.feeds = {
   "https://neovim.io/news.xml"
}
local db = require("feed.db")
local eq = MiniTest.expect.equality
local h = require("tests.helpers")
local M = require("feed.commands")

local function new_db()
   db:blowup()
   db = db.new()
end

T = MiniTest.new_set({
   hooks = {
      post_case = new_db,
   },
})

T['_sync_feedlist'] = function()
   M._sync_feedlist()
   eq({}, db.feeds["https://neovim.io/news.xml"])
end

T['opml'] = function()
   M.load_opml.impl("./data/opml_web.xml")
   eq(236, vim.tbl_count(db.feeds))
   M.export_opml.impl("data/export_opml")
   local export = vim.fs.find({ 'export_opml' }, { path = "./data" })[1]
   assert(export)
   vim.fn.delete(export)
end

-- T['update_feed'] = function()
--    M.update_feed.impl("https://neovim.io/news.xml")
--
-- end

return T
