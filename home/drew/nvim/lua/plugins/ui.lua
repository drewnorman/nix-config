return {
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
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
        },
    },
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = {
            options = {
                theme = "papercolor_light",
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
        },
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            local highlight = {
                "RainbowRed",
                "RainbowYellow",
                "RainbowBlue",
                "RainbowOrange",
                "RainbowGreen",
                "RainbowViolet",
                "RainbowCyan",
            }
            local hooks = require("ibl.hooks")
            hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
                vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
                vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
                vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
                vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
                vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
                vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
                vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
            end)
            require("ibl").setup({
                indent = { highlight = highlight },
                whitespace = { highlight = highlight, remove_blankline_trail = false },
            })
        end,
    },
    {
        "karb94/neoscroll.nvim",
        event = "VeryLazy",
        opts = {
            duration_multiplier = 0.7,
            easing = "quadratic",
            mappings = {
                "<C-u>",
                "<C-d>",
                "<C-b>",
                "<C-f>",
                "<C-y>",
                "<C-e>",
                "zt",
                "zz",
                "zb",
            },
        },
    },
    {
        "stevearc/aerial.nvim",
        cmd = "AerialToggle",
        opts = {
            backends = { "lsp", "treesitter", "markdown", "man" },
            layout = { min_width = 28 },
            show_guides = true,
        },
        keys = {
            { "<leader>ta", "<cmd>AerialToggle<cr>", desc = "Toggle outline" },
        },
    },
}
