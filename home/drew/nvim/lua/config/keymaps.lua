local map = vim.keymap.set
local commands = require("config.commands")
local opts = { noremap = true, silent = true }

local function find_notes_dir()
    local dir = vim.fn.getcwd()
    local home = vim.env.HOME
    while true do
        if vim.fn.isdirectory(dir .. "/notes") == 1 then
            return dir .. "/notes"
        end
        if dir == home or dir == "/" then break end
        dir = vim.fn.fnamemodify(dir, ":h")
    end
    return home .. "/notes"
end

-- Notes
map("n", "<leader>ni", function()
    vim.cmd("edit " .. vim.fn.fnameescape(find_notes_dir() .. "/inbox.md"))
end, vim.tbl_extend("force", opts, { desc = "Notes inbox" }))
map("n", "<leader>nt", function()
    vim.cmd("edit " .. vim.fn.fnameescape(find_notes_dir() .. "/todo.md"))
end, vim.tbl_extend("force", opts, { desc = "Notes todo" }))

-- Backslash as fallback comma (comma is leader).
map({ "n", "x", "o" }, "\\", ",", opts)

-- Open init.lua in a vertical split for editing.
map("n", "<leader>ev", function()
    vim.cmd("vsplit " .. vim.fn.fnameescape(vim.env.MYVIMRC))
end, vim.tbl_extend("force", opts, { desc = "Edit config" }))

map("n", "<leader>hl", function()
    if vim.v.hlsearch == 1 and vim.o.hlsearch then
        vim.cmd.nohlsearch()
    else
        vim.o.hlsearch = true
    end
end, vim.tbl_extend("force", opts, { desc = "Toggle search highlight" }))

map({ "n", "v", "o" }, "<leader>ss", "<cmd>w<cr>", vim.tbl_extend("force", opts, { desc = "Save" }))
map({ "n", "v", "o" }, "<leader>bb", function()
    commands.run_project_script("build")
end, vim.tbl_extend("force", opts, { desc = "Build project" }))
map({ "n", "v", "o" }, "<leader>dd", function()
    commands.run_project_script("deploy")
end, vim.tbl_extend("force", opts, { desc = "Deploy project" }))
map({ "n", "v", "o" }, "<leader>rr", function()
    commands.run_project_script("run")
end, vim.tbl_extend("force", opts, { desc = "Run project" }))
map({ "n", "v", "o" }, "<leader>xx", commands.stop_last_task, vim.tbl_extend("force", opts, { desc = "Stop task" }))
map({ "n", "v", "o" }, "<leader>qf", commands.toggle_tasks, vim.tbl_extend("force", opts, { desc = "Toggle tasks" }))

map({ "n", "v", "o" }, "<leader>wq", "<cmd>q<cr>", vim.tbl_extend("force", opts, { desc = "Close window" }))
map(
    { "n", "v", "o" },
    "<leader>wk",
    "<cmd>bp|sp|bn|bd|q<cr>",
    vim.tbl_extend("force", opts, { desc = "Close buffer and window" })
)
map("n", "<leader>bp", "<cmd>bp<cr>", vim.tbl_extend("force", opts, { desc = "Previous buffer" }))
map("n", "<leader>bn", "<cmd>bn<cr>", vim.tbl_extend("force", opts, { desc = "Next buffer" }))
map("n", "<leader>bl", "<cmd>buffers<cr>", vim.tbl_extend("force", opts, { desc = "List buffers" }))
map("n", "<leader>bd", "<cmd>bp|sp|bn|bd<cr>", vim.tbl_extend("force", opts, { desc = "Delete buffer" }))
map("n", "<leader>bk", "<cmd>bp|sp|bn|bd!<cr>", vim.tbl_extend("force", opts, { desc = "Delete buffer force" }))

map("n", "<leader>te", commands.open_terminal, vim.tbl_extend("force", opts, { desc = "Open terminal" }))
map("t", "<Esc><Esc>", "<C-\\><C-n>", opts)

-- Cargo shortcuts.
map("n", "<leader>rsb", "<cmd>terminal cargo build<cr>", vim.tbl_extend("force", opts, { desc = "Cargo build" }))
map("n", "<leader>rsr", "<cmd>terminal cargo run<cr>", vim.tbl_extend("force", opts, { desc = "Cargo run" }))
map("n", "<leader>rst", "<cmd>terminal cargo test<cr>", vim.tbl_extend("force", opts, { desc = "Cargo test" }))
map("n", "<leader>rsc", "<cmd>terminal cargo clean<cr>", vim.tbl_extend("force", opts, { desc = "Cargo clean" }))
map("n", "<leader>rsd", "<cmd>terminal cargo doc<cr>", vim.tbl_extend("force", opts, { desc = "Cargo doc" }))
