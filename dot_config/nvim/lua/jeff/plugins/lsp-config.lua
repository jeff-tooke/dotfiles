return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    local lspconfig = require "lspconfig"
    local mason_lspconfig = require "mason-lspconfig"

    mason_lspconfig.setup {
      handlers = {
        function(server_name)
          lspconfig[server_name].setup {}
        end,

        ["ansiblels"] = function()
          lspconfig.ansiblels.setup()
        end,
        ["bashls"] = function()
          lspconfig.bashls.setup()
        end,
        ["dockerls"] = function()
          lspconfig.dockerls.setup()
        end,
        ["gopls"] = function()
          lspconfig.gopls.setup()
        end,
        ["jsonls"] = function()
          lspconfig.jsonls.setup()
        end,
        ["lua_ls"] = function()
          lspconfig.lua_ls.setup {
            settings = {
              Lua = {
                diagnostics = {
                  globals = { "vim" },
                },
              },
            },
          }
        end,
        ["marksman"] = function()
          lspconfig.marksman.setup()
        end,
        ["pyright"] = function()
          lspconfig.pyright.setup()
        end,
        ["terraformls"] = function()
          lspconfig.terraformls.setup()
        end,
        ["yamlls"] = function()
          lspconfig.yamlls.setup()
        end,
      },
    }
  end,
}
