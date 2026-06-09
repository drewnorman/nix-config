return {
    "NLKNguyen/papercolor-theme",
    lazy = false,
    priority = 1000,
    config = function()
        local variant = os.getenv("DREW_THEME_VARIANT") or "light"

        vim.o.background = variant
        vim.cmd.colorscheme("PaperColor")

        local transparent_groups = {
            "Normal",
            "NormalNC",
            "NormalFloat",
            "FloatBorder",
            "SignColumn",
            "LineNr",
            "CursorLineNr",
            "EndOfBuffer",
            "MsgArea",
            "NonText",
            "WinSeparator",
        }

        for _, group in ipairs(transparent_groups) do
            pcall(vim.api.nvim_set_hl, 0, group, { bg = "NONE" })
        end

        if variant == "light" then
            pcall(vim.api.nvim_set_hl, 0, "ColorColumn", { bg = "lightgrey" })
        else
            pcall(vim.api.nvim_set_hl, 0, "ColorColumn", { bg = "#303030" })
        end
    end,
}
