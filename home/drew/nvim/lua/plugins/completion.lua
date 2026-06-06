return {
    { "L3MON4D3/LuaSnip" },
    { "rafamadriz/friendly-snippets" },
    {
        "saghen/blink.cmp",
        dependencies = { "saghen/blink.lib", "L3MON4D3/LuaSnip", "rafamadriz/friendly-snippets" },
        config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
            require("luasnip").filetype_extend("twig", { "html" })

            require("blink.cmp").setup({
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
            })
        end,
    },
}
