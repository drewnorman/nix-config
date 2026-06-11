local specs = {}

for _, module in ipairs({
    "plugins.colorscheme",
    "plugins.treesitter",
    "plugins.lsp",
    "plugins.completion",
    "plugins.git",
    "plugins.ui",
    "plugins.editing",
}) do
    local module_specs = require(module)

    if (module_specs[1] and type(module_specs[1]) == "string") or module_specs.dir or module_specs.url then
        table.insert(specs, module_specs)
    else
        vim.list_extend(specs, module_specs)
    end
end

return specs
