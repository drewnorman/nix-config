return {
    "NLKNguyen/papercolor-theme",
    lazy = false,
    priority = 1000,
    config = function()
        local variant = os.getenv("DREW_THEME_VARIANT") or "light"

        vim.o.background = variant
        vim.cmd.colorscheme("PaperColor")

        if variant == "light" then
            vim.api.nvim_set_hl(0, "Normal", { bg = "white" })
            vim.api.nvim_set_hl(0, "LineNr", { bg = "white" })
            vim.api.nvim_set_hl(0, "ColorColumn", { bg = "lightgrey" })
        end
    end,
}
