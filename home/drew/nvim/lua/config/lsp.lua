local ok, blink = pcall(require, "blink.cmp")
local php_stubs = require("config.php_stubs")

if vim.lsp.config == nil or vim.lsp.enable == nil then
    return
end

vim.diagnostic.config({
    virtual_text = true,
    underline = true,
    severity_sort = true,
    float = { border = "rounded" },
    signs = true,
})

local capabilities = ok and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()

local on_attach = function(_, bufnr)
    local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, noremap = true, desc = desc })
    end

    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
    map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
    map("n", "gr", vim.lsp.buf.references, "Go to references")
    map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
    map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
    map("n", "gl", vim.diagnostic.open_float, "Line diagnostic")
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "<leader>sh", vim.lsp.buf.signature_help, "Signature help")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>ci", "<cmd>LspInfo<cr>", "LSP info")
    map("n", "<leader>cr", "<cmd>LspRestart<cr>", "Restart LSP")
    map("n", "<leader>fI", function()
        require("fzf-lua").lsp_incoming_calls()
    end, "Incoming calls")
    map("n", "<leader>fO", function()
        require("fzf-lua").lsp_outgoing_calls()
    end, "Outgoing calls")
    map("n", "<leader>ih", function()
        local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
    end, "Toggle inlay hints")
end

local default_config = {
    on_attach = on_attach,
    capabilities = capabilities,
}

local servers = {
    cssls = vim.tbl_deep_extend("force", default_config, {
        settings = {
            css = { colorDecorators = false },
            scss = { colorDecorators = false },
            less = { colorDecorators = false },
        },
    }),
    html = default_config,
    intelephense = vim.tbl_deep_extend("force", default_config, {
        settings = {
            intelephense = {
                environment = { phpVersion = "8.2" },
                stubs = php_stubs,
            },
        },
    }),
    jdtls = default_config,
    jsonls = default_config,
    lua_ls = vim.tbl_deep_extend("force", default_config, {
        settings = {
            Lua = { diagnostics = { globals = { "vim" } } },
        },
    }),
    tailwindcss = vim.tbl_deep_extend("force", default_config, {
        settings = { tailwindCSS = { colorDecorators = false } },
    }),
    nixd = default_config,
    ts_ls = default_config,
    vue_ls = default_config,
}

for server, config in pairs(servers) do
    vim.lsp.config(server, config)
end

vim.lsp.enable(vim.tbl_keys(servers))
