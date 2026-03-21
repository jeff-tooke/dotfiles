return {

  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "b0o/schemastore.nvim",
  },
  config = function()
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    local lspconfig = require "lspconfig"
    local mason_lspconfig = require "mason-lspconfig"
    local schemastore = require "schemastore"

    mason_lspconfig.setup {
      ensure_installed = {
        "ansiblels",
        "bashls",
        "dockerls",
        "gopls",
        "jsonls",
        "lua_ls",
        "marksman",
        "pyright",
        "terraformls",
        "yamlls",
      },
      handlers = {
        function(server_name)
          lspconfig[server_name].setup {
            capabilities = capabilities,
          }
        end,

        ["ansiblels"] = function()
          lspconfig.ansiblels.setup {
            capabilities = capabilities,
          }
        end,
        ["bashls"] = function()
          lspconfig.bashls.setup {
            capabilities = capabilities,
          }
        end,
        ["dockerls"] = function()
          lspconfig.dockerls.setup {
            capabilities = capabilities,
          }
        end,
        ["gopls"] = function()
          lspconfig.gopls.setup {
            capabilities = capabilities,
          }
        end,
        ["jsonls"] = function()
          lspconfig.jsonls.setup {
            capabilities = capabilities,
          }
        end,
        ["lua_ls"] = function()
          lspconfig.lua_ls.setup {
            capabilities = capabilities,
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
          lspconfig.marksman.setup {
            capabilities = capabilities,
          }
        end,
        ["pyright"] = function()
          lspconfig.pyright.setup {
            capabilities = capabilities,
          }
        end,
        ["terraformls"] = function()
          lspconfig.terraformls.setup {
            capabilities = capabilities,
          }
        end,
        ["yamlls"] = function()
          lspconfig.yamlls.setup {
            capabilities = capabilities,
            settings = {
              yaml = {
                keyOrdering = false,
                schemas = schemastore.yaml.schemas(),
              },
            },
          }
        end,
      },
    }
  end,
}
