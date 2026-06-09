return {
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        config = function()
            require("which-key").setup({
                preset = "helix",
                spec = {
                    { "<leader>b", group = "buffers" },
                    { "<leader>c", group = "code" },
                    { "<leader>d", group = "deploy" },
                    { "<leader>f", group = "find" },
                    { "<leader>h", group = "hunks" },
                    { "<leader>i", group = "inlay" },
                    { "<leader>j", group = "jump" },
                    { "<leader>l", group = "lazygit" },
                    { "<leader>r", group = "run" },
                    { "<leader>rs", group = "rust" },
                    { "<leader>s", group = "save/search" },
                    { "<leader>t", group = "toggle/tools" },
                    { "<leader>w", group = "windows" },
                    { "<leader>x", group = "stop" },
                },
            })
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        config = function()
            local variant = os.getenv("DREW_THEME_VARIANT") or "light"
            local lualine_theme = variant == "dark" and "papercolor_dark" or "papercolor_light"

            if not pcall(require, "lualine.themes." .. lualine_theme) then
                lualine_theme = "auto"
            end

            require("lualine").setup({
                options = {
                    theme = lualine_theme,
                    section_separators = "",
                    component_separators = "|",
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch", "diff", "diagnostics" },
                    lualine_c = { { "filename", path = 1 } },
                    lualine_x = { "encoding", "fileformat", "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
            })
        end,
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        event = "VeryLazy",
        config = function()
            local highlight = {
                "RainbowRed", "RainbowYellow", "RainbowBlue",
                "RainbowOrange", "RainbowGreen", "RainbowViolet", "RainbowCyan",
            }
            local hooks = require("ibl.hooks")
            hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
                vim.api.nvim_set_hl(0, "RainbowRed",    { fg = "#E06C75" })
                vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
                vim.api.nvim_set_hl(0, "RainbowBlue",   { fg = "#61AFEF" })
                vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
                vim.api.nvim_set_hl(0, "RainbowGreen",  { fg = "#98C379" })
                vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
                vim.api.nvim_set_hl(0, "RainbowCyan",   { fg = "#56B6C2" })
                vim.api.nvim_set_hl(0, "IblScope",      { fg = "#0087AF" })
            end)
            require("ibl").setup({
                indent = { highlight = highlight },
                scope = { highlight = "IblScope" },
                whitespace = { highlight = highlight, remove_blankline_trail = false },
            })
        end,
    },
    {
        "karb94/neoscroll.nvim",
        config = function()
            require("neoscroll").setup({
                duration_multiplier = 0.7,
                easing = "quadratic",
                mappings = {
                    "<C-u>", "<C-d>", "<C-b>", "<C-f>",
                    "<C-y>", "<C-e>", "zt", "zz", "zb",
                },
            })
        end,
    },
    {
        "stevearc/aerial.nvim",
        cmd = "AerialToggle",
        keys = {
            { "<leader>ta", "<cmd>AerialToggle<cr>", mode = "n", desc = "Toggle outline" },
        },
        config = function()
            require("aerial").setup({
                backends = { "lsp", "treesitter", "markdown", "man" },
                layout = { min_width = 28 },
                show_guides = true,
            })
        end,
    },
}
