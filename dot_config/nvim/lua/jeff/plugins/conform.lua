return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require "conform"

    conform.setup {
      formatters_by_ft = {
        ["*"] = { "codespell" },
        ["_"] = { "trim_whitespace" },
        ansible = { "ansible-lint" },
        bash = { "shellcheck" },
        json = { "prettier" },
        lua = { "stylua" },
        markdown = { "prettier" },
        nix = { "nixfmt" },
        python = { "isort", "black" },
        terraform = { "terraform_fmt" },
        yaml = { "prettier" },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
      format_on_save = {
        lsp_fallback = true,
        async = false,
        timeout_ms = 5000,
      },
    }

    vim.keymap.set({ "n", "v" }, "<leader>mp", function()
      conform.format {
        lsp_fallback = true,
        async = false,
        timeout_ms = 5000,
      }
    end, { desc = "Format file or range (in visual mode)" })
  end,
}
