return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile"},
  config = function()
    local conform = required("conform")

    conform.setup({
      formatters_by_ft = {
        ["*"] = { "codespell"},
        ["_"] = { "trim_whitespace"},
        ansible = { "ansible-lint" },
        bash = { "shellcheck" },
        json = { "prettier" },
        lua = { "stylua" },
        markdown = { "prettier "},
        nix = { "nixfmt"},
        python = { "isort", "black" },
        terraform = { "terrafrom_fmt"},
        yaml = { "prettier" },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
      format_on_save = {
        lsp_fallback = true,
        async = false,
        timeout_ms = 500,
      },
    })

    vim.keymap.set({ "n", "v"}, "<leader>mp", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 500,
      })
    end, { desc = "Format file or range (in visual mode)" })
  end,
}
