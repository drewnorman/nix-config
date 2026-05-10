return {
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            current_line_blame_opts = { delay = 500 },
            on_attach = function(bufnr)
                local gs = require("gitsigns")
                local map = function(mode, l, r, desc)
                    vim.keymap.set(mode, l, r, { buffer = bufnr, silent = true, desc = desc })
                end

                map("n", "]h", gs.next_hunk, "Next hunk")
                map("n", "[h", gs.prev_hunk, "Prev hunk")
                map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
                map("v", "<leader>hs", function()
                    gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "Stage hunk")
                map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
                map("n", "<leader>hu", gs.undo_stage_hunk, "Unstage hunk")
                map("n", "<leader>hb", function()
                    gs.blame_line({ full = true })
                end, "Blame line")
                map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle inline blame")
            end,
        },
    },
    {
        "kdheepak/lazygit.nvim",
        cmd = "LazyGit",
        keys = {
            { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
        },
        dependencies = { "nvim-lua/plenary.nvim" },
    },
}
