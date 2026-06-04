local nix = require(vim.g.nix_info_plugin_name)
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

local servers = {}

if nix(false, "info", "lsp", "emmet") then
    servers.emmet_language_server = default_config
end

if nix(false, "info", "lsp", "intelephense") then
    servers.intelephense = vim.tbl_deep_extend("force", default_config, {
        settings = {
            intelephense = {
                environment = { phpVersion = "8.2" },
                stubs = php_stubs,
            },
        },
    })
end

if nix(false, "info", "lsp", "jdtls") then
    servers.jdtls = default_config
end

if nix(false, "info", "lsp", "lua") then
    servers.lua_ls = vim.tbl_deep_extend("force", default_config, {
        settings = {
            Lua = { diagnostics = { globals = { "vim" } } },
        },
    })
end

if nix(false, "info", "lsp", "nix") then
    servers.nixd = default_config
end

if nix(false, "info", "lsp", "tailwind") then
    servers.tailwindcss = vim.tbl_deep_extend("force", default_config, {
        settings = { tailwindCSS = { colorDecorators = false } },
    })
end

if nix(false, "info", "lsp", "typescript") then
    servers.ts_ls = default_config
    servers.vue_ls = default_config
end

if nix(false, "info", "lsp", "vscode") then
    servers.cssls = vim.tbl_deep_extend("force", default_config, {
        settings = {
            css  = { colorDecorators = false },
            scss = { colorDecorators = false },
            less = { colorDecorators = false },
        },
    })
    servers.html   = default_config
    servers.jsonls = default_config
end

for server, config in pairs(servers) do
    vim.lsp.config(server, config)
end

vim.lsp.enable(vim.tbl_keys(servers))
