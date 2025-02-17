-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.cmd([[let &rtp.=','.getcwd()]])

for f in vim.fs.dir("./deps/pack/deps/opt/") do
   vim.opt.runtimepath:append("," .. "./deps/pack/deps/opt/" .. f)
end

-- Set up 'mini.test' only when calling headless Neovim (like with `make test`)
if #vim.api.nvim_list_uis() == 0 then
   -- Add 'mini.nvim' to 'runtimepath' to be able to use 'mini.test'
   -- Assumed that 'mini.nvim' is stored in 'deps/mini.nvim'
   vim.cmd("set rtp+=deps/mini.nvim")
   path = vim.api.nvim_get_runtime_file("parser/xml.so", true)[1]

   print(path)

   vim.treesitter.language.add("xml", {
      path = vim.api.nvim_get_runtime_file("parser/xml.so", false)[1],
   })

   -- Set up 'mini.test'
   require("mini.test").setup()
end
