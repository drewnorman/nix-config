-- Open a shell in a vertical split.
local function open_terminal()
    vim.cmd.vsplit()
    vim.cmd("terminal " .. vim.o.shell)
end

local function project_root()
    local name = vim.api.nvim_buf_get_name(0)
    local start = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()

    return vim.fs.root(start, { ".git" }) or vim.uv.cwd()
end

local function run_project_script(name)
    local root = project_root()
    local script = vim.fs.joinpath(root, "bin", name .. ".sh")

    if vim.fn.filereadable(script) ~= 1 then
        vim.notify("No project script found: " .. script, vim.log.levels.WARN)
        return
    end

    local overseer = require("overseer")
    local task = overseer.new_task({
        name = "bin/" .. name .. ".sh",
        cmd = script,
        cwd = root,
        components = {
            "default",
            "unique",
        },
    })

    task:start()
    overseer.open({ enter = false })
end

local function stop_last_task()
    local overseer = require("overseer")
    local tasks = overseer.list_tasks({ recent_first = true })

    if #tasks == 0 then
        vim.notify("No Overseer tasks to stop", vim.log.levels.INFO)
        return
    end

    tasks[1]:stop()
end

local function toggle_tasks()
    require("overseer").toggle({ enter = false, direction = "bottom" })
end

return {
    open_terminal = open_terminal,
    run_project_script = run_project_script,
    stop_last_task = stop_last_task,
    toggle_tasks = toggle_tasks,
}
