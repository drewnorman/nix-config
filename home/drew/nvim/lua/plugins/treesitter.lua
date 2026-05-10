return {
    {
        "nvim-treesitter/nvim-treesitter",
        dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            local ok, treesitter = pcall(require, "nvim-treesitter.configs")
            if not ok then
                return
            end

            treesitter.setup({
                ensure_installed = {
                    "bash",
                    "c",
                    "css",
                    "diff",
                    "html",
                    "java",
                    "javascript",
                    "json",
                    "lua",
                    "markdown",
                    "nix",
                    "markdown_inline",
                    "php",
                    "query",
                    "regex",
                    "rust",
                    "tsx",
                    "twig",
                    "typescript",
                    "vim",
                    "vimdoc",
                    "vue",
                    "xml",
                    "yaml",
                },
                auto_install = true,
                highlight = { enable = true },
                indent = { enable = true },
                textobjects = {
                    move = {
                        enable = true,
                        set_jumps = true,
                        goto_next_start = {
                            ["]f"] = "@function.outer",
                            ["]c"] = "@class.outer",
                        },
                        goto_next_end = {
                            ["]F"] = "@function.outer",
                            ["]C"] = "@class.outer",
                        },
                        goto_previous_start = {
                            ["[f"] = "@function.outer",
                            ["[c"] = "@class.outer",
                        },
                        goto_previous_end = {
                            ["[F"] = "@function.outer",
                            ["[C"] = "@class.outer",
                        },
                    },
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            ["af"] = "@function.outer",
                            ["if"] = "@function.inner",
                            ["ac"] = "@class.outer",
                            ["ic"] = "@class.inner",
                        },
                    },
                    swap = {
                        enable = true,
                        swap_next = { [">f"] = "@function.outer" },
                        swap_previous = { ["<f"] = "@function.outer" },
                    },
                },
            })
        end,
    },
}
