local Config = require("sesh.config")
local M = {}
M._active = false

local e = vim.fn.fnameescape

---Ensures that Config.autosave.criteria is of the following form:
---
---     {
---         buffers = <number>,
---         splits = <number>,
---         tabs = <number>,
---     }
---
---This is necessary because the user is allowed to use numbers, booleans, or nil to
---specify criteria,
---@param items table?
---@return sesh.autosaveCriteria
local function normalize_criteria(items)
    if items == nil then
        return { buffers = 1, splits = 0, tabs = 0 }
    end
    items.buffers = items.buffers or 0
    items.splits = items.splits or 0
    items.tabs = items.tabs or 0
    for c, n in ipairs(items) do
        if type(n) == "boolean" then
            items[c] = n == true and 1 or 0
        end
    end
    return items
end

---@return boolean true if the minimum number of bufs are open
local function handle_buf(min_bufs)
    if min_bufs == 0 then
        return false
    end
    local to_delete = {}
    local bufs = vim.tbl_filter(function(b)
        local ignore = {
            "gitcommit",
            "gitrebase",
            "jj",
        }
        if
            vim.bo[b].buftype ~= ""
            or vim.tbl_contains(ignore, vim.bo[b].filetype)
            or vim.api.nvim_buf_get_name(b) == ""
        then
            to_delete[b] = true
            return false
        end
        return true
    end, vim.api.nvim_list_bufs())
    for bufnr in pairs(to_delete) do
        vim.api.nvim_buf_delete(bufnr, {})
    end
    if #bufs < min_bufs then
        return false
    end
    return true
end

---@return boolean true if the minimum number of splits are open
local function handle_split(min_splits)
    if min_splits == 0 then
        return false
    end
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        if #vim.api.nvim_tabpage_list_wins(tab) >= min_splits then
            return true
        end
    end
    return false
end

---@return boolean true if the minimum number of tabs are open
local function handle_tab(min_tabs)
    return min_tabs == 0 and false or #vim.api.nvim_list_tabpages() >= min_tabs
end

---@package
---Gets current branch name.
---@return string?
function M.branch()
    if vim.uv.fs_stat(".git") then
        local ret = vim.fn.systemlist("git branch --show-current")[1]
        return vim.v.shell_error == 0 and ret or nil
    end
end

---@package
---Executes autocommands specified by a Sesh event.
---@param event string
function M.exec_auto(event)
    vim.api.nvim_exec_autocmds("User", {
        pattern = "SESH" .. event,
    })
end

---@package
---Registers autocommand for autosaving feature.
function M.register()
    if M.options.autosave.enabled == false then
        return
    end
    M._active = true
    local criteria = normalize_criteria(M.options.autosave.criteria)
    local handlers = {
        buffers = handle_buf,
        splits = handle_split,
        tabs = handle_tab,
    }

    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("SESH", { clear = true }),
        callback = function()
            M.exec_auto("SavePre")
            for k, v in pairs(criteria) do
                if handlers[k](v) then
                    M.save()
                    M.exec_auto("SavePost")
                    return
                end
            end
        end,
    })
end

---@package
---Lists all saved sessions and sorts them in descending order according to creation
---time.
---@return string[]
function M.list()
    ---@type string[]
    local sessions = vim.fn.glob(M.options.dir .. "*.vim", true, true)
    table.sort(sessions, function(a, b)
        return vim.uv.fs_stat(a).mtime.sec > vim.uv.fs_stat(b).mtime.sec
    end)
    return sessions
end

---@package
---Returns the most recent session.
---@return string
function M.last()
    return M.list()[1]
end

---@package
---Computes and returns the name for the current session.
---@param opts? {branch?: boolean}
---@return string
function M.current(opts)
    opts = opts or {}
    local name = vim.fn.getcwd():gsub("[\\/:]+", "%%")
    if M.options.use_branch and opts.branch then
        local branch = M.branch()
        if branch and branch ~= "main" and branch ~= "master" then
            name = name .. "%%" .. branch:gsub("[\\/:]+", "%%")
        end
    end
    return M.options.dir .. name .. ".vim"
end

---@package
---Disables autosaving for current neovim process.
function M.stop()
    M._active = false
    pcall(vim.api.nvim_del_augroup_by_name, "SESH")
end

---Returns true if Sesh.nvim is currently active, ie if session will be autosaved before
---exiting vim, and false otherwise.
---@return boolean
function M.active()
    vim.notify("SESH: autosave is active", vim.log.levels.INFO)
    return M._active
end

---Saves a session to the directory specified in config.
function M.save()
    vim.cmd("mks! " .. e(M.current()))
end

---Deletes all saved sessions.
function M.clean()
    for _, session in ipairs(M.list()) do
        vim.fs.rm(session)
    end
end

---@return boolean true if session for cwd exists
function M.exists()
    return vim.tbl_contains(M.list(), M.current())
end

---Deletes saved session for cwd.
function M.delete()
    if not M.exists() then
        vim.notify("SESH: current session does not exist", vim.log.levels.DEBUG)
    end
    vim.fs.rm(M.current())
end

---@package
---Opens a picker for saved sessions using `vim.ui.select`.
function M.select()
    ---@type { session: string, dir: string, branch?: string }[]
    local items = {}
    ---@type table<string, boolean>
    local have = {}

    for _, session in ipairs(M.list()) do
        if vim.uv.fs_stat(session) then
            local file = session:sub(#M.options.dir + 1, -5)
            local dir, branch = unpack(vim.split(file, "%%", { plain = true }))
            dir = dir:gsub("%%", "/")
            if jit.os:find("Windows") then
                dir = dir:gsub("^(%w)/", "%1:/")
            end
            if not have[dir] then
                have[dir] = true
                items[#items + 1] = { session = session, dir = dir, branch = branch }
            end
        end
    end
    if #items > 0 then
        vim.ui.select(items, {
            prompt = "Select a session: ",
            format_item = function(item)
                return vim.fn.fnamemodify(item.dir, ":p:~")
            end,
        }, function(item)
            if item then
                vim.fn.chdir(item.dir)
                M.load()
            end
        end)
    end
end

---Loads the session for the cwd if it exists.
---@param opts? { last?: boolean }
function M.load(opts)
    if #vim.fn.argv() > 0 then
        vim.notify(
            "SESH: Neovim was opened with additional args. Aborting session autoload.",
            vim.log.levels.INFO
        )
        return
    end
    opts = opts or {}
    ---@type string
    local file
    if opts.last then
        file = M.last()
    else
        file = M.current()
        if vim.fn.filereadable(file) == 0 then
            file = M.current({ branch = false })
        end
    end
    if file and vim.fn.filereadable(file) ~= 0 then
        M.exec_auto("LoadPre")
        vim.cmd("silent! source " .. e(file))
        M.exec_auto("LoadPost")
    end
end

---@class NvimCommandOpts
---@field name string
---@field args string
---@field fargs table
---@field nargs string
---@field bang boolean
---@field line1 number
---@field line2 number
---@field range number
---@field count number
---@field reg string
---@field mods string
---@field smods string

---@package
---Controls `:Sesh[!] [subcommand]`. If the <bang> suffix is included with the `:Sesh`
---command, turns off autosaving if it is on. If no subcommand is included, defaults to
---`:Sesh select`.
---@param opts NvimCommandOpts
function M.action(opts)
    local subcommands = {
        ["+"] = M.save,
        ["-"] = M.delete,
        ["<"] = M.load,
        ["~"] = M.clean,
        ["?"] = M.active,
        ["clean"] = M.clean,
        ["del"] = M.delete,
        ["load"] = M.load,
        ["save"] = M.save,
        ["select"] = M.select,
        ["unknown"] = function()
            vim.notify("SESH: unknown commands", vim.log.levels.ERROR)
        end,
    }
    if #opts.fargs == 0 then
        if opts.bang then
            M.stop()
            return
        end
        opts.args = "select"
    end
    local action = subcommands[opts.args] or subcommands.unknown
    action(M)
    if opts.bang then
        M.stop()
    end
end

---@param opts sesh.Config
function M.setup(opts)
    ---@type sesh.Config
    M.options = vim.tbl_deep_extend("force", {}, Config.default, opts or {})
    vim.fn.mkdir(M.options.dir, "p")
    vim.api.nvim_create_user_command("Sesh", M.action, { bang = true, nargs = "*" })

    if M.options.autosave then
        M.register()
    end
    if M.options.autoload then
        local gitfiles = {
            "%.git/commit_editmsg",
            "%.git/merge_msg",
            "%.git/rebase%-editmsg",
            "%.git/squash_msg",
        }
        local buf = vim.api.nvim_buf_get_name(0):lower()
        -- if neovim is opened as a git editor, do not auto-load
        for _, gitfile in ipairs(gitfiles) do
            if buf:find(gitfile) then
                return
            end
        end
        M.load()
    end
end

return M
