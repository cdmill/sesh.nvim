# sesh.nvim

a fork of Folke's [persistence.nvim](https://github.com/folke/persistence.nvim) customized to my workflow.

## ✨ Features

- simple API to save, load, and manage sessions
- options to automatically save or load sessions
- *smart autoloading* := don't autoload session if neovim was opened as the git editor or if
  neovim was opened with a file argument
- *smart autosaving* := specify minimum number of buffers, splits, or tabs to trigger autosave

## ⚡️ Requirements

- Neovim >= 0.7.2

## 📦 Installation

Install the plugin with your preferred package manager:


### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- Lua
{
  "cdmill/sesh.nvim",
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  }
}
```

## ⚙️ Configuration

SESH.nvim comes with the following defaults:

```lua
{
    -- directory where session files are saved
    dir = vim.fn.stdpath("state") .. "/sessions/",
    autosave = {
        enabled = false, -- if true, autosave session before exiting
        -- criteria = {
        --     buffers = 2, -- min number to trigger autosaving
        --     tabs = false, -- use false or don't specify criteria to ignore
        --     splits = 0, -- equivalent to false
        -- },
    },
    -- if true, auto-loads session (if one exists) when starting vim
    autoload = false,
    -- if true, use git branch to save session
    use_branch = true,
}
```

## 🚀 Usage

- Open session picker `:Sesh`.
- Check if SESH.nvim has autosave enabled `:Sesh?`.
- Disable autosave if it is enabled `:Sesh!`.
- Save session for cwd `:Sesh save`.
- Load session for cwd `:Sesh load`.
- Delete saved session for cwd `:Sesh del`.
- Delete all saved sessions `:Sesh clean`.

Add the `<bang>` suffix to `Sesh` on any command to disable autosaving for the cwd. For
example, running `:Sesh! del` will delete the session for the cwd and disable autosaving
if enabled.

Other supported suffixes are as follows:

- `:Sesh+` == `:Sesh save`
- `:Sesh-` == `:Sesh del`
- `:Sesh<` == `:Sesh load`
- `:Sesh~` == `:Sesh clean`

## Inspiration

- Folke [persistence.nvim](https://github.com/folke/persistence.nvim)
- Pocco81 [neovim-session-manager](https://github.com/Shatur/neovim-session-manager)
