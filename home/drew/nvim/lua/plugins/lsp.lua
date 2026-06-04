return {
    {
        "neovim/nvim-lspconfig",
        config = function()
            require("config.lsp")
        end,
    },
    {
        "j-hui/fidget.nvim",
        config = function()
            require("fidget").setup({})
        end,
    },
}
