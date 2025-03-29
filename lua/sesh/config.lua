local M = {}

---@class (exact) sesh.Config
---directory where session files are saved
---@field dir? string
---if true, use git branch to save session
---@field use_branch? boolean
---if true, auto-loads session (if one exsits) when starting vim
---@field autoload? boolean
---if true, auto-saves session before exiting vim. if a number, specifies the minimum
---number of file buffers to be open for a session to be saved. note that autosave=true
---is equivalent to autosave=0
---@field autosave? boolean|integer
M.default = {
    dir = vim.fn.stdpath("state") .. "/sessions/",
    autosave = false,
    autoload = false,
    use_branch = true,
}

return M
