vim.cmd [[let &rtp.=','.getcwd()]]

vim.cmd "set rtp+=deps/mini.nvim"
require("mini.deps").setup { path = { package = "deps/" } }

local add = MiniDeps.add

add {
   source = "nvim-treesitter/nvim-treesitter",
}
require("nvim-treesitter.configs").setup {
   ensure_installed = { "xml", "html", "markdown" },
}

add {
   source = "MunifTanjim/nui.nvim",
}

add {
   source = "gregorias/coop.nvim",
}

add {
   source = "nvim-lua/plenary.nvim",
}

add {
   source = "pysan3/pathlib.nvim",
}

add {
   source = "nvim-neotest/nvim-nio",
}

os.exit()
