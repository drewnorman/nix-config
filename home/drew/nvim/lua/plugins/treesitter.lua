local filetype_languages = {
    bash = "bash",
    c = "c",
    css = "css",
    diff = "diff",
    help = "vimdoc",
    html = "html",
    java = "java",
    javascript = "javascript",
    json = "json",
    lua = "lua",
    markdown = "markdown",
    nix = "nix",
    php = "php",
    query = "query",
    regex = "regex",
    rust = "rust",
    sh = "bash",
    twig = "twig",
    typescript = "typescript",
    typescriptreact = "tsx",
    vim = "vim",
    vue = "vue",
    xml = "xml",
    yaml = "yaml",
}

vim.api.nvim_create_autocmd("FileType", {
    pattern = vim.tbl_keys(filetype_languages),
    callback = function(args)
        local language = filetype_languages[vim.bo[args.buf].filetype]
        vim.treesitter.start(args.buf, language)

        local ok, indent_query = pcall(vim.treesitter.query.get, language, "indents")
        if ok and indent_query then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})

require("nvim-treesitter-textobjects").setup({
    move = {
        set_jumps = true,
    },
    select = {
        lookahead = true,
    },
})

local move = require("nvim-treesitter-textobjects.move")
local select = require("nvim-treesitter-textobjects.select")
local swap = require("nvim-treesitter-textobjects.swap")

vim.keymap.set({ "x", "o" }, "af", function()
    select.select_textobject("@function.outer", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "if", function()
    select.select_textobject("@function.inner", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "ac", function()
    select.select_textobject("@class.outer", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "ic", function()
    select.select_textobject("@class.inner", "textobjects")
end)

vim.keymap.set({ "n", "x", "o" }, "]f", function()
    move.goto_next_start("@function.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "]c", function()
    move.goto_next_start("@class.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "]F", function()
    move.goto_next_end("@function.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "]C", function()
    move.goto_next_end("@class.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "[f", function()
    move.goto_previous_start("@function.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "[c", function()
    move.goto_previous_start("@class.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "[F", function()
    move.goto_previous_end("@function.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "[C", function()
    move.goto_previous_end("@class.outer", "textobjects")
end)

vim.keymap.set("n", ">f", function()
    swap.swap_next("@function.outer")
end)
vim.keymap.set("n", "<f", function()
    swap.swap_previous("@function.outer")
end)
