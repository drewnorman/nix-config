vim.g.mapleader = ','
vim.g.maplocalleader = ','

local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
vim.opt.rtp:prepend(config_dir)
package.path = config_dir .. "/lua/?.lua;" .. config_dir .. "/lua/?/init.lua;" .. package.path

require('config.options')
require('config.autocmds')
require('config.commands')
require('config.keymaps')
require('plugins.treesitter')

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup(require("plugins"), {
  lockfile = config_dir .. "/lazy-lock.json",
  change_detection = {
    notify = false,
  },
  performance = {
    reset_packpath = false,
    cache = {
      enabled = false,
    },
    rtp = {
      reset = false,
      disabled_plugins = {
        "gzip",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
