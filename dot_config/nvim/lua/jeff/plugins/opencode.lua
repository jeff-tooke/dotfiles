return {
  "nickjvandyke/opencode.nvim",
  version = "*",
  dependencies = {
    {
      "folke/snacks.nvim",
      optional = true,
      opts = {
        input = {},
        picker = {
          actions = {
            opencode_send = function(...)
              return require("opencode").snacks_picker_send(...)
            end,
          },
          win = {
            input = {
              keys = {
                ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
              },
            },
          },
        },
      },
    },
  },
  config = function()
    vim.g.opencode_opts = {
      server = {
        term = {
          win = {
            position = "right",
            width = 0.35,
          },
        },
      },
      events = { reload = true },
    }
    vim.o.autoread = true

    vim.api.nvim_create_autocmd("TermOpen", {
      callback = function(ev)
        if vim.api.nvim_buf_get_name(ev.buf):match "opencode" then
          vim.schedule(function()
            vim.bo[ev.buf].filetype = "opencode_term"
          end)
        end
      end,
    })
  end,
  keys = {
    {
      "<leader>oc",
      function()
        require("opencode").toggle()
      end,
      desc = "Toggle OpenCode",
    },
    {
      "<leader>oa",
      function()
        require("opencode").ask("@this: ", { submit = true })
      end,
      desc = "Ask OpenCode",
      mode = { "n", "x" },
    },
    {
      "<leader>os",
      function()
        require("opencode").select()
      end,
      desc = "OpenCode select",
    },
  },
}
