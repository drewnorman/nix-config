return {
    { "mason-org/mason.nvim", build = ":MasonUpdate", lazy = false, opts = {} },
    { "j-hui/fidget.nvim", event = "LspAttach", opts = {} },
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "mason-org/mason.nvim" },
        lazy = false,
        opts = {
            ensure_installed = {
                "pint",
                "prettier",
                "stylua",
            },
        },
    },
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
            "mason-org/mason.nvim",
            "neovim/nvim-lspconfig",
        },
        lazy = false,
        opts = {
            ensure_installed = {
                "cssls",
                "emmet-language-server",
                "html",
                "intelephense",
                "jdtls",
                "jsonls",
                "lua_ls",
                "nixd",
                "tailwindcss",
                "ts_ls",
                "vue_ls",
            },
            automatic_enable = false,
        },
    },
    { "neovim/nvim-lspconfig", lazy = false },
}
