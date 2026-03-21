return {
  "coder/claudecode.nvim",
  config = function()
    require("claudecode").setup {
      terminal = {
        provider = "snacks",
        split_side = "right",
        split_width_percentage = 0.35,
      },
    }

    -- Tag the Claude terminal buffer so lualine can target it
    -- with a custom extension (flat dark statusline, name only)
    vim.api.nvim_create_autocmd("TermOpen", {
      callback = function(ev)
        if vim.api.nvim_buf_get_name(ev.buf):match "claude" then
          vim.schedule(function()
            vim.bo[ev.buf].filetype = "claudecode_term"
          end)
        end
      end,
    })
  end,
  keys = {
    { "<leader>cc", "<cmd>ClaudeCodeFocus<cr>", desc = "Toggle Claude Code" },
    { "<leader>cs", "<cmd>ClaudeCodeSend<cr>", desc = "Send to Claude", mode = { "n", "v" } },
    { "<leader>cd", "<cmd>ClaudeCodeDiff<cr>", desc = "Claude diff" },
    { "<leader>ca", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer to Claude" },
    { "<leader>cr", "<cmd>ClaudeCode --resume<cr>", desc = "Resume last Claude session" },
    { "<leader>cn", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude conversation" },
  },
} -- return {
--   "coder/claudecode.nvim",
--   opts = {
--     terminal = {
--       provider = "snacks",
--       position = "right",
--       size = 0.35,
--     },
--   },
--   keys = {
--     { "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
--     { "<leader>cs", "<cmd>ClaudeCodeSend<cr>", desc = "Send to Claude", mode = { "n", "v" } },
--     { "<leader>cd", "<cmd>ClaudeCodeDiff<cr>", desc = "Claude diff" },
--   },
-- }
