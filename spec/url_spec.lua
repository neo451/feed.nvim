local urlview = require "feed.urlview"

describe("urlview", function()
   it("should remove links from text and return all links as a list", function()
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
      assert.same(expected, res)
      assert.same(expected_links, res_links)
   end)
end)
