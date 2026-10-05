local config = require("feed.config")
local db = require("feed.db")
local pandoc = require("feed.pandoc")
local ui = require("feed.ui")
local eq = MiniTest.expect.equality

local original_config = rawget(config, "config")
local original_convert = pandoc.convert
local id = "entry-highlight-test"
local original_entry = rawget(db, id)
local buf

local T = MiniTest.new_set({
   hooks = {
      post_case = function()
         config.config = original_config
         pandoc.convert = original_convert
         rawset(db, id, original_entry)
         if buf and vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
         end
      end,
   },
})

local function highlights()
   local ns = vim.api.nvim_get_namespaces().feed_entry
   return vim.tbl_map(function(mark)
      return { mark[2], mark[3], mark[4].hl_group }
   end, vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true }))
end

T["entry metadata highlights follow the configured layout"] = function()
   config.config = vim.deepcopy(config._default)
   config.config.entry = {
      order = { "author", "title" },
      author = {
         color = "FeedAuthor",
         format = function()
            return "An author"
         end,
      },
      title = {
         color = "FeedTitle",
         format = function()
            return "A title"
         end,
      },
   }

   rawset(db, id, {})
   pandoc.convert = function() end
   buf = vim.api.nvim_create_buf(false, true)

   ui.show_entry({ buf = buf, id = id })

   eq({ "Author: An author", "Title: A title", "" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
   eq({ { 0, 8, "FeedAuthor" }, { 1, 7, "FeedTitle" } }, highlights())

   config.config.entry.order = { "title" }
   ui.show_entry({ buf = buf, id = id })

   eq({ { 0, 7, "FeedTitle" } }, highlights())
end

T["entry links are not truncated"] = function()
   config.config = vim.deepcopy(config._default)
   config.config.entry = {
      order = { "link" },
      link = config._default.entry.link,
   }

   local link = "https://pdrl.fm/f3efd0/dts.podtrac.com/redirect.mp3/arttrk.com/p/ST44R/claritaspod.com/media/episode/owen-wilson.mp3"
   rawset(db, id, { link = link })
   pandoc.convert = function() end
   buf = vim.api.nvim_create_buf(false, true)

   ui.show_entry({ buf = buf, id = id })

   eq({ "Link: <" .. link .. ">", "" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
end

return T
