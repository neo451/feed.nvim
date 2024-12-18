local config = require "feed.config"
config.db_dir = "~/.feed.nvim.test/"
local db = require "feed.db"
local M = require "feed.ui"
local urlview = require "feed.ui.urlview"
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T.urlview = function()
   local str = [[1. autolink: <https://neovim.io/news>
2. link: [neovim](https://neovim.io)
3. img: ![image](https://neovim.io/image1)]]
   local expected = {
      "1. autolink: <https://neovim.io/news>",
      "2. link: [neovim]",
      "3. img: ![image]",
   }
   local expected_links = {
      { "https://neovim.io/news", "https://neovim.io/news" },
      { "neovim", "https://neovim.io" },
      { "Image 1", "https://neovim.io/image1" },
      { "entry url", "https://neovim.io" },
   }
   local res, res_links = urlview(vim.split(str, "\n"), "https://neovim.io")
   eq(expected, res)
   eq(expected_links, res_links)
end

-- T["ui"] = MiniTest.new_set {
--    post_once = function()
--       -- db:blowup()
--    end,
-- }
--
-- T["ui"]["get_entry"] = function()
--    function DB(entries)
--       for i, v in ipairs(entries) do
--          v.content = ""
--          v.id = v.id or tostring(i)
--          v.time = v.time or i
--          db:add(v)
--       end
--    end
--
--    DB { {}, {}, {} }
--    M.show_index()
--    -- vim.print(db.index)
-- end

return T
