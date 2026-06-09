return {
    {
        url = "https://codeberg.org/andyg/leap.nvim",
        name = "leap.nvim",
        keys = {
            { "<leader>jj", "<Plug>(leap-forward)",       mode = { "n", "x", "o" }, remap = true, desc = "Leap forward" },
            { "<leader>jl", "<Plug>(leap-forward-till)",  mode = { "n", "x", "o" }, remap = true, desc = "Leap forward till" },
            { "<leader>jk", "<Plug>(leap-backward)",      mode = { "n", "x", "o" }, remap = true, desc = "Leap backward" },
            { "<leader>jh", "<Plug>(leap-backward-till)", mode = { "n", "x", "o" }, remap = true, desc = "Leap backward till" },
            { "<leader>jw", "<Plug>(leap-cross-window)",  mode = { "n", "x", "o" }, remap = true, desc = "Leap window" },
        },
        config = function()
            require("leap").opts.vim_opts["go.ignorecase"] = false
        end,
    },
    {
        "stevearc/overseer.nvim",
        lazy = true,
        cmd = {
            "OverseerBuild",
            "OverseerClearCache",
            "OverseerClose",
            "OverseerDeleteBundle",
            "OverseerInfo",
            "OverseerLoadBundle",
            "OverseerOpen",
            "OverseerQuickAction",
            "OverseerRun",
            "OverseerRunCmd",
            "OverseerSaveBundle",
            "OverseerTaskAction",
            "OverseerToggle",
        },
        config = function()
            require("overseer").setup({
                task_list = {
                    direction = "bottom",
                    min_height = 10,
                    max_height = 18,
                    default_detail = 1,
                },
                form = { border = "rounded" },
                confirm = { border = "rounded" },
                task_win = { border = "rounded" },
            })
        end,
    },
    {
        "mikavilpas/yazi.nvim",
        event = "VeryLazy",
        cmd = "Yazi",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            { "<leader>fb", "<cmd>Yazi<cr>", mode = { "n", "v" }, desc = "File browser" },
        },
        opts = {
            open_for_directories = true,
            floating_window_scaling_factor = 0.9,
            yazi_floating_window_border = "single",
        },
    },
    {
        "ibhagwan/fzf-lua",
        keys = {
            { "<leader>ff", function() require("fzf-lua").files() end,                  mode = "n", desc = "Find files" },
            { "<leader>fi", function() require("fzf-lua").live_grep() end,              mode = "n", desc = "Grep files" },
            { "<leader>fs", function() require("fzf-lua").lsp_document_symbols() end,   mode = "n", desc = "Document symbols" },
            { "<leader>fS", function() require("fzf-lua").lsp_workspace_symbols() end,  mode = "n", desc = "Workspace symbols" },
            { "<leader>fd", function() require("fzf-lua").diagnostics_document() end,   mode = "n", desc = "Document diagnostics" },
            { "<leader>fD", function() require("fzf-lua").diagnostics_workspace() end,  mode = "n", desc = "Workspace diagnostics" },
        },
        config = function()
            local actions = require("fzf-lua.actions")
            require("fzf-lua").setup({
                winopts = {
                    width = 0.9,
                    height = 0.8,
                    backdrop = false,
                    border = "rounded",
                    preview = { layout = "horizontal", ratio = 50 },
                },
                files = {
                    cmd = "rg --files --hidden --iglob !.git/",
                },
                actions = {
                    files = {
                        ["enter"]  = actions.file_edit,
                        ["ctrl-s"] = actions.file_split,
                        ["ctrl-v"] = actions.file_vsplit,
                        ["ctrl-t"] = actions.file_tabedit,
                    },
                },
            })
        end,
    },
    {
        "christoomey/vim-tmux-navigator",
        config = function()
            local opts = { silent = true }
            vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>",  opts)
            vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>",  opts)
            vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>",    opts)
            vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", opts)
        end,
    },
    {
        "kylechui/nvim-surround",
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup({})
        end,
    },
    {
        "stevearc/conform.nvim",
        keys = {
            {
                "<leader>cf",
                function()
                    require("conform").format({ async = true, lsp_fallback = true })
                end,
                mode = { "n", "v" },
                desc = "Format buffer",
            },
        },
        config = function()
            require("conform").setup({
                formatters_by_ft = {
                    lua        = { "stylua" },
                    javascript = { "prettierd", "prettier" },
                    typescript = { "prettierd", "prettier" },
                    vue        = { "prettierd", "prettier" },
                    css        = { "prettierd", "prettier" },
                    html       = { "prettierd", "prettier" },
                    json       = { "prettierd", "prettier" },
                    php        = { "php-cs-fixer" },
                    rust       = { "rustfmt" },
                },
            })
        end,
    },
    { "tpope/vim-abolish" },
    { "wincent/ferret" },
}
