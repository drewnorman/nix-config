vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- Load core editor behavior before plugin-backed features.
require('config.options')
require('config.autocmds')
require('config.commands')
require('config.keymaps')
require('plugins')

require('config.lsp')
