local augroup = vim.api.nvim_create_augroup("user_config", { clear = true })

-- Preserve explicit Vue filetype detection from the Vimscript config.
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    group = augroup,
    pattern = "*.vue",
    callback = function()
        vim.bo.filetype = "vue"
    end,
})

-- Drop straight into insert mode for terminal buffers.
vim.api.nvim_create_autocmd("TermOpen", {
    group = augroup,
    pattern = "*",
    command = "startinsert",
})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "twig",
    callback = function(args)
        -- Reuse HTML tag matching in Twig buffers while keeping Twig's own
        -- ftplugin settings intact.
        if not vim.bo[args.buf].matchpairs:find("<:>", 1, true) then
            vim.bo[args.buf].matchpairs = vim.bo[args.buf].matchpairs .. ",<:>"
        end

        if vim.g.loaded_matchit ~= nil and vim.b[args.buf].match_words == nil then
            vim.b[args.buf].match_ignorecase = 1
            vim.b[args.buf].match_words = table.concat({
                "<!--:-->",
                "<:>",
                "<\\@<=[ou]l\\>[^>]*\\%(>\\|$\\):<\\@<=li\\>:<\\@<=/[ou]l>",
                "<\\@<=dl\\>[^>]*\\%(>\\|$\\):<\\@<=d[td]\\>:<\\@<=/dl>",
                "<\\@<=\\([^/!][^ \\t>]*\\)[^>]*\\%(>\\|$\\):<\\@<=/\\1>",
            }, ",")
        end
    end,
})
