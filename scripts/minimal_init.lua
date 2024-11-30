-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.cmd [[let &rtp.=','.getcwd()]]

vim.opt.runtimepath:append ",~/.local/share/nvim/site/pack/deps/opt/nvim-treesitter/"
vim.opt.runtimepath:append ",~/.local/share/nvim/site/pack/deps/opt/pathlib.nvim/"
vim.opt.runtimepath:append ",~/.local/share/nvim/site/pack/deps/opt/nvim-nio/"

-- Set up 'mini.test' only when calling headless Neovim (like with `make test`)
if #vim.api.nvim_list_uis() == 0 then
   -- Add 'mini.nvim' to 'runtimepath' to be able to use 'mini.test'
   -- Assumed that 'mini.nvim' is stored in 'deps/mini.nvim'
   vim.cmd "set rtp+=deps/mini.nvim"

   -- Set up 'mini.test'
   require("mini.test").setup()
end
