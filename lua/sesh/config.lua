local M = {}

---@class sesh.autosaveCriteria
---@field buffers number|boolean|nil min # of bufs to trigger autosave
---@field splits number|boolean|nil min # of splits to trigger autosave
---@field tabs number|boolean|nil min # of tabs to trigger autosave

---@class sesh.autosaveOpts
---@field enabled boolean if true, autosave session before exiting
---@field criteria? sesh.autosaveCriteria

---@class (exact) sesh.Config
---directory where session files are saved
---@field dir? string
---if true, use git branch to save session
---@field use_branch? boolean
---if true, auto-loads session (if one exsits) when starting vim
---@field autoload? boolean
---@field autosave? sesh.autosaveOpts
M.default = {
    dir = vim.fn.stdpath("state") .. "/sessions/",
    autosave = {
        enabled = false,
        -- criteria = {
        --     buffers = 2,
        --     splits = false,
        --     tabs = false,
        -- },
    },
    autoload = false,
    use_branch = true,
}

return M
