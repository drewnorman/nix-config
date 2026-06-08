return {
    {
        url = "https://codeberg.org/andyg/leap.nvim",
        name = "leap.nvim",
        config = function()
            require("leap").opts.vim_opts["go.ignorecase"] = false
            local map = vim.keymap.set
            local opts = { silent = true }
            map({ "n", "x", "o" }, "<leader>jj", "<Plug>(leap-forward)",       { remap = true, desc = "Leap forward" })
            map({ "n", "x", "o" }, "<leader>jl", "<Plug>(leap-forward-till)",  { remap = true, desc = "Leap forward till" })
            map({ "n", "x", "o" }, "<leader>jk", "<Plug>(leap-backward)",      { remap = true, desc = "Leap backward" })
            map({ "n", "x", "o" }, "<leader>jh", "<Plug>(leap-backward-till)", { remap = true, desc = "Leap backward till" })
            map({ "n", "x", "o" }, "<leader>jw", "<Plug>(leap-cross-window)",  { remap = true, desc = "Leap window" })
        end,
    },
    {
        "stevearc/overseer.nvim",
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
            local map = vim.keymap.set
            local opts = { silent = true }
            map("n", "<leader>ff", function() require("fzf-lua").files() end,                  vim.tbl_extend("force", opts, { desc = "Find files" }))
            map("n", "<leader>fi", function() require("fzf-lua").live_grep() end,              vim.tbl_extend("force", opts, { desc = "Grep files" }))
            map("n", "<leader>fs", function() require("fzf-lua").lsp_document_symbols() end,  vim.tbl_extend("force", opts, { desc = "Document symbols" }))
            map("n", "<leader>fS", function() require("fzf-lua").lsp_workspace_symbols() end, vim.tbl_extend("force", opts, { desc = "Workspace symbols" }))
            map("n", "<leader>fd", function() require("fzf-lua").diagnostics_document() end,  vim.tbl_extend("force", opts, { desc = "Document diagnostics" }))
            map("n", "<leader>fD", function() require("fzf-lua").diagnostics_workspace() end, vim.tbl_extend("force", opts, { desc = "Workspace diagnostics" }))
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
        config = function()
            require("nvim-surround").setup({})
        end,
    },
    {
        "stevearc/conform.nvim",
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
            vim.keymap.set({ "n", "v" }, "<leader>cf", function()
                require("conform").format({ async = true, lsp_fallback = true })
            end, { silent = true, desc = "Format buffer" })
        end,
    },
    { "tpope/vim-abolish" },
    { "wincent/ferret" },
}
