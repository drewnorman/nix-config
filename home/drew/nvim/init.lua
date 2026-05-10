vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- Load core editor behavior before plugin-backed features.
require('config.options')
require('config.autocmds')
require('config.commands')
require('config.keymaps')
require('plugins')

-- Load plugin-backed behavior after lazy.nvim is initialized.
require('config.lsp')
