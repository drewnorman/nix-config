local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
    local result = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })

    if vim.v.shell_error ~= 0 then
        vim.schedule(function()
            vim.notify("lazy.nvim bootstrap failed: " .. result, vim.log.levels.ERROR)
        end)
        return
    end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = {
        { import = "plugins.colorscheme" },
        { import = "plugins.treesitter" },
        { import = "plugins.lsp" },
        { import = "plugins.completion" },
        { import = "plugins.git" },
        { import = "plugins.ui" },
        { import = "plugins.editing" },
    },
    defaults = {
        lazy = true,
    },
})
