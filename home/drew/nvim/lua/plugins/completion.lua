return {
    {
        "saghen/blink.cmp",
        version = "1.*",
        event = "InsertEnter",
        dependencies = {
            "rafamadriz/friendly-snippets",
            {
                "L3MON4D3/LuaSnip",
                version = "v2.*",
                config = function()
                    require("luasnip.loaders.from_vscode").lazy_load()
                    require("luasnip").filetype_extend("twig", { "html" })
                end,
            },
        },
        opts = {
            snippets = { preset = "luasnip" },
            sources = {
                default = { "lsp", "path", "snippets", "buffer" },
            },
            keymap = {
                preset = "default",
                ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
                ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
            },
            completion = {
                documentation = {
                    auto_show = true,
                    window = { border = "rounded" },
                },
                menu = { border = "rounded" },
                ghost_text = { enabled = true },
            },
        },
        opts_extend = { "sources.default" },
    },
}
