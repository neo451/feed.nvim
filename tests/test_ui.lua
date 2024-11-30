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

return T
