vim.g.mapleader = ','
vim.g.maplocalleader = ','

local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
vim.opt.rtp:prepend(config_dir)
package.path = config_dir .. "/lua/?.lua;" .. config_dir .. "/lua/?/init.lua;" .. package.path

local function nix_treesitter_runtime()
  local ok, nix_info = pcall(require, "nix-info")
  if ok then
    return nix_info(nil, "plugins", "start", "nvim-treesitter-runtime")
  end
end

local function use_nix_treesitter_runtime()
  local treesitter_runtime = nix_treesitter_runtime()
  if treesitter_runtime then
    vim.opt.runtimepath:prepend(treesitter_runtime)
  end
end

use_nix_treesitter_runtime()

require('config.options')
require('config.autocmds')
require('config.commands')
require('config.keymaps')

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
    cache = {
      enabled = false,
    },
    rtp = {
      paths = (function()
        local treesitter_runtime = nix_treesitter_runtime()
        return treesitter_runtime and { treesitter_runtime } or {}
      end)(),
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

use_nix_treesitter_runtime()
