return {
    "nickchahley/papercolor-theme-slim",
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd.colorscheme("PaperColorSlimLight")
        vim.api.nvim_set_hl(0, "Normal", { bg = "white" })
        vim.api.nvim_set_hl(0, "LineNr", { bg = "white" })
        vim.api.nvim_set_hl(0, "ColorColumn", { bg = "lightgrey" })
    end,
}
