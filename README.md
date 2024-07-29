# Project Explorer for neovim

Simple project manager and explorer for neovim

## Features

- List Projects based of pattern
- Create new projects directory
- Delete projects directory
- Add projects to favorites
- List favorites projects only

## Installation

- Lazy.nvim

```lua
return {
  "Rics-Dev/project-explorer.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  opts = {
    paths = { "~/dev/*", "~/dev" }, -- Custom paths
    -- by default paths are set to ~/dev , ~/projects
  },
  config = function(_, opts)
    require("project_explorer").setup(opts)
  end,
  keys = {
    { "<leader>fp", "<cmd>ProjectExplorer<cr>", desc = "Project Explorer" },
  },
  -- Ensure the plugin is loaded correctly
  lazy = false,
}
```

## How to use

Default keybinding is `<leader>fp` to open the project explorer
you can also open it by executing `:ProjectExplorer`

- To cd into a project just press `Enter` on the selected project.
- To Add a project use `<C-a>`.
- To delete a project use `<C-d>`.
- To add a project to favorite projects use `<C-S-f>` ( Favorite projects are marked with ⭐).
- To display favorite projects only use `<C-f>`.
