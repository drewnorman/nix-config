return {
    {
        url = "https://codeberg.org/andyg/leap.nvim",
        keys = {
            {
                "<leader>jj",
                "<Plug>(leap-forward)",
                mode = { "n", "x", "o" },
                desc = "Leap forward",
                remap = true,
            },
            {
                "<leader>jl",
                "<Plug>(leap-forward-till)",
                mode = { "n", "x", "o" },
                desc = "Leap forward till",
                remap = true,
            },
            {
                "<leader>jk",
                "<Plug>(leap-backward)",
                mode = { "n", "x", "o" },
                desc = "Leap backward",
                remap = true,
            },
            {
                "<leader>jh",
                "<Plug>(leap-backward-till)",
                mode = { "n", "x", "o" },
                desc = "Leap backward till",
                remap = true,
            },
            {
                "<leader>jw",
                "<Plug>(leap-cross-window)",
                mode = { "n", "x", "o" },
                desc = "Leap window",
                remap = true,
            },
        },
        config = function()
            require("leap").opts.vim_opts["go.ignorecase"] = false
        end,
    },
    {
        "stevearc/overseer.nvim",
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
        opts = {
            task_list = {
                direction = "bottom",
                min_height = 10,
                max_height = 18,
                default_detail = 1,
            },
            form = { border = "rounded" },
            confirm = { border = "rounded" },
            task_win = { border = "rounded" },
        },
    },
    {
        "mikavilpas/yazi.nvim",
        opts = {
            open_for_directories = true,
            floating_window_scaling_factor = 0.9,
            yazi_floating_window_border = "single",
        },
        keys = {
            { "<leader>fb", "<cmd>Yazi<cr>", desc = "File browser" },
        },
    },
    {
        "ibhagwan/fzf-lua",
        dependencies = { { "junegunn/fzf", build = "./install --all" } },
        keys = {
            {
                "<leader>ff",
                function()
                    require("fzf-lua").files()
                end,
                desc = "Find files",
            },
            {
                "<leader>fi",
                function()
                    require("fzf-lua").live_grep()
                end,
                desc = "Grep files",
            },
            {
                "<leader>fs",
                function()
                    require("fzf-lua").lsp_document_symbols()
                end,
                desc = "Document symbols",
            },
            {
                "<leader>fS",
                function()
                    require("fzf-lua").lsp_workspace_symbols()
                end,
                desc = "Workspace symbols",
            },
            {
                "<leader>fd",
                function()
                    require("fzf-lua").diagnostics_document()
                end,
                desc = "Document diagnostics",
            },
            {
                "<leader>fD",
                function()
                    require("fzf-lua").diagnostics_workspace()
                end,
                desc = "Workspace diagnostics",
            },
        },
        config = function()
            local actions = require("fzf-lua.actions")
            require("fzf-lua").setup({
                winopts = {
                    width = 0.9,
                    height = 0.8,
                    backdrop = false,
                    border = "rounded",
                    preview = {
                        layout = "horizontal",
                        ratio = 50,
                    },
                },
                files = {
                    cmd = "rg --files --hidden --iglob !.git/",
                },
                actions = {
                    files = {
                        ["enter"] = actions.file_edit,
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
        cmd = {
            "TmuxNavigateLeft",
            "TmuxNavigateDown",
            "TmuxNavigateUp",
            "TmuxNavigateRight",
        },
        keys = {
            { "<C-h>", "<cmd>TmuxNavigateLeft<cr>" },
            { "<C-j>", "<cmd>TmuxNavigateDown<cr>" },
            { "<C-k>", "<cmd>TmuxNavigateUp<cr>" },
            { "<C-l>", "<cmd>TmuxNavigateRight<cr>" },
        },
    },
    { "wincent/ferret", cmd = { "Ack", "Acks", "Back", "Black", "Lack", "Lacks", "Quack" } },
    { "kylechui/nvim-surround", version = "*", event = "VeryLazy", config = true },
    { "tpope/vim-abolish", event = "VeryLazy" },
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
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                vue = { "prettier" },
                css = { "prettier" },
                html = { "prettier" },
                json = { "prettier" },
                php = { "pint" },
                rust = { "rustfmt" },
            },
        },
    },
}
