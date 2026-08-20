vim.pack.add({
    'https://github.com/rebelot/kanagawa.nvim',
    'https://github.com/nvim-tree/nvim-web-devicons',
    'https://github.com/nvim-lualine/lualine.nvim',
}, { load = true })

vim.cmd.colorscheme 'kanagawa'
require('lualine').setup()
