return {
    "NLKNguyen/papercolor-theme",
    lazy = false,
    priority = 1000,
    config = function()
        local state_file = vim.fn.expand("~/.local/state/drew-theme")
        local function read_variant()
            local f = io.open(state_file, "r")
            if f then
                local v = vim.trim(f:read("*l") or "")
                f:close()
                if v == "light" or v == "dark" then return v end
            end
            return os.getenv("DREW_THEME_VARIANT") or "light"
        end

        local variant = read_variant()
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
            pcall(vim.api.nvim_set_hl, 0, "Comment", { fg = "#b0b0b0", italic = true })
            pcall(vim.api.nvim_set_hl, 0, "LineNr", { fg = "#a8a8a8", bg = "NONE" })
            pcall(vim.api.nvim_set_hl, 0, "CursorLineNr", { fg = "#e0e0e0", bg = "NONE", bold = true })
            pcall(vim.api.nvim_set_hl, 0, "NonText", { fg = "#8a8a8a", bg = "NONE" })
            pcall(vim.api.nvim_set_hl, 0, "EndOfBuffer", { fg = "#6f6f6f", bg = "NONE" })
            pcall(vim.api.nvim_set_hl, 0, "WinSeparator", { fg = "#7a7a7a", bg = "NONE" })
            pcall(vim.api.nvim_set_hl, 0, "FoldColumn", { fg = "#a8a8a8", bg = "NONE" })
            pcall(vim.api.nvim_set_hl, 0, "SignColumn", { fg = "#a8a8a8", bg = "NONE" })
            pcall(vim.api.nvim_set_hl, 0, "NormalFloat", { fg = "#e0e0e0", bg = "NONE" })
            pcall(vim.api.nvim_set_hl, 0, "FloatBorder", { fg = "#8a8a8a", bg = "NONE" })
        end
    end,
}
