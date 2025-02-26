local M = require("feed.parser.html")
local eq = MiniTest.expect.equality

local src = [[
<p><img src="/images/2016-vimfest.jpg" style="max-width:600px; height:auto;" title="Neovim and Vim maintainers at VimFest 2016" /></p>
<p><img src="https://neovim.io/images/2017-vimfest.jpg" style="max-width:600px; height:auto;" title="Neovim and Vim maintainers at VimFest 2016" /></p>
]]

local T = MiniTest.new_set()

T["parse"] = function()
   local expected = [[
<p><img src="https://neovim.io/images/2016-vimfest.jpg" style="max-width:600px; height:auto;" title="Neovim and Vim maintainers at VimFest 2016" /></p>
<p><img src="https://neovim.io/images/2017-vimfest.jpg" style="max-width:600px; height:auto;" title="Neovim and Vim maintainers at VimFest 2016" /></p>
]]
   eq(M.resolve(src, "https://neovim.io/news.xml"), expected)
end

return T
