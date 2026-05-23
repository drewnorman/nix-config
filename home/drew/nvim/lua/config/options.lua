-- Set editor defaults and UI behavior that do not depend on plugins.
vim.opt.shortmess:append("I")
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.autoindent = true
vim.opt.tabstop = 8
vim.opt.softtabstop = 0
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.smarttab = true
vim.opt.colorcolumn = "80"
vim.opt.textwidth = 0
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevelstart = 10
local zsh = vim.fn.exepath("zsh")
if zsh ~= "" then
    vim.opt.shell = zsh
end
vim.opt.timeout = true
vim.opt.timeoutlen = 500
vim.opt.ttimeout = true
vim.opt.ttimeoutlen = 20
vim.opt.updatetime = 100
vim.opt.background = "light"
vim.opt.guicursor = "n-v-sm:block-Cursor,i-ci-c-ve:ver25-Cursor,r-cr-o:hor20-Cursor"
vim.opt.winborder = "rounded"
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 8
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.undofile = true
vim.opt.smoothscroll = true

if vim.fn.executable("rg") == 1 then
    vim.opt.grepprg = "rg --vimgrep"
end

vim.env.BASH_ENV = vim.fn.expand("~/.zsh_aliases")
