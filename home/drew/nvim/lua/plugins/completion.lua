pcall(function()
    require("luasnip.loaders.from_vscode").lazy_load()
    require("luasnip").filetype_extend("twig", { "html" })
end)

local ok, blink = pcall(require, "blink.cmp")
if not ok then
    return
end

blink.setup({
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
