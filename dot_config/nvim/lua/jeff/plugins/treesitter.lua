return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewfile" },
  build = ":TSUpdate",
  config = function()
    local treesitter = require "nvim-treesitter.configs"

    -- configure treesitter
    treesitter.setup {
      highlight = {
        enable = true,
      },
      indent = {
        enable = true,
      },
      ensure_installed = {
        "bash",
        "dockerfile",
        "gitignore",
        "gotmpl",
        "hcl",
        "json",
        "lua",
        "make",
        "markdown",
        "nix",
        "python",
        "regex",
        "terraform",
        "toml",
        "yaml",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    }

    -- set helm and chezmoi templates as gotmpl filetype
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
      pattern = { "*.tpl", "*tmpl" },
      command = "set filetype=gotmpl",
    })
  end,
}
