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
        end
    end,
}
