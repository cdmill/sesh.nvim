local M = {}

---@class sesh.autosaveOpts
---@field enabled boolean if true, autosave session before exiting
---@field criteria? table number of "buffers", "splits", or "tabs" to use as condition
---for autosaving

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
        --     tabs = false,
        --     splits = false,
        -- },
    },
    autoload = false,
    use_branch = true,
}

return M
