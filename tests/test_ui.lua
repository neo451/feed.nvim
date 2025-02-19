local config = require("feed.config")
config.db_dir = "~/.feed.nvim.test/"
local db = require("feed.db")
local M = require("feed.ui")
local get_urls = require("feed.utils").get_urls
local remove_links = require("feed.utils").remove_links
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T.urlview = function()
   local str = [[1. autolink: <https://neovim.io/news>
2. link: [neovim](https://neovim.io)
3. img: ![Image 1](https://neovim.io/image1)]]

   local expected_links = {
      { "https://neovim.io", "https://neovim.io" },
      { "https://neovim.io/news", "https://neovim.io/news" },
      { "neovim", "https://neovim.io" },
      { "Image 1", "https://neovim.io/image1" },
   }
   local res_links = get_urls(str, "https://neovim.io")
   eq(expected_links, res_links)
end

T.remove_links = function()
   local str = [[1. autolink: <https://neovim.io/news>
2. link: [neovim](https://neovim.io)
3. img: ![Image 1](https://neovim.io/image1)]]
   local expected = [[1. autolink: <https://neovim.io/news>
2. link: [neovim]()
3. img: ![Image 1]()]]
   eq(remove_links(str, get_urls(str, "https://neovim.io")), expected)
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
