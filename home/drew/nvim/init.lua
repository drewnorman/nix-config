vim.g.mapleader = ','
vim.g.maplocalleader = ','

local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
vim.opt.rtp:prepend(config_dir)
package.path = config_dir .. "/lua/?.lua;" .. config_dir .. "/lua/?/init.lua;" .. package.path
local initial_packpath = vim.o.packpath

local function prefer_nix_treesitter_grammars()
  local grammar_dirs = vim.fn.globpath(initial_packpath, "pack/*/start/COLLATED_TS_GRAMMARS", false, true)

  if #grammar_dirs > 0 then
    vim.opt.runtimepath:prepend(grammar_dirs[1])
  end

  for _, parser_path in ipairs(vim.fn.globpath(initial_packpath, "pack/*/start/tree-sitter-*/parser", false, true)) do
    local grammar_root = vim.fn.fnamemodify(parser_path, ":h")
    local metadata_path = grammar_root .. "/tree-sitter.json"

    if vim.fn.filereadable(metadata_path) == 1 then
      local ok, metadata = pcall(vim.json.decode, table.concat(vim.fn.readfile(metadata_path), "\n"))

      if ok and type(metadata.grammars) == "table" then
        for _, grammar in ipairs(metadata.grammars) do
          if grammar.name then
            pcall(vim.treesitter.language.add, grammar.name, { path = parser_path })
          end
        end
      end
    end
  end
end

prefer_nix_treesitter_grammars()

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

prefer_nix_treesitter_grammars()
