local util = require("feed.utils")

local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T["get_urls"] = function()
   local src = [[**Links**

[^1] <https://neovim.io/doc/user/api.html>

[^2] <https://www.reddit.com/user/jlombera>

[^3] <https://www.reddit.com/r/neovim/comments/1ku3d78/nonremote_neovim_plugins_written_in_c/>]]
   local urls = util.get_urls(nil, vim.split(src, "\n"))
   eq({
      "https://neovim.io/doc/user/api.html",
      "https://www.reddit.com/user/jlombera",
      "https://www.reddit.com/r/neovim/comments/1ku3d78/nonremote_neovim_plugins_written_in_c/",
   }, urls)
end

return T
