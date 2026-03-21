vim.g.mapleader = " "

local keymap = vim.keymap

-- Keep cursor centred
keymap.set("n", "j", "jzz", { noremap = true, silent = true, desc = "Centre cursor while navigating down" })
keymap.set("n", "k", "kzz", { noremap = true, silent = true, desc = "Centre cursor while navigating up" })

-- Get that muscle memory going;
keymap.set({ "n", "v" }, "<Up>", "<Nop>", opts)
keymap.set({ "n", "v" }, "<Down>", "<Nop>", opts)
keymap.set({ "n", "v" }, "<Left>", "<Nop>", opts)
keymap.set({ "n", "v" }, "<Right>", "<Nop>", opts)

-- Custom stuff
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })
keymap.set("n", "<leader>e", ":Oil<CR>", { desc = "Open file explorer" })
keymap.set("n", "<leader>w", ":up<CR>", { noremap = true, silent = true, desc = "Save buffer" })
-- keymap.set("n", "<leader>q", ":wqa<CR>", { noremap = true, silent = true, desc = "Save and exit all buffers" })
keymap.set("n", "<leader>q", function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and vim.bo[buf].modified then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd "write"
      end)
    end
  end
  vim.cmd "qa!"
end, { noremap = true, silent = true, desc = "Save and exit all buffers" })
keymap.set("n", "<leader>bc", ":up <bar> %bd <bar> e# <bar> bd# <CR>", { noremap = true, silent = true, desc = "Update and close all buffers except current" })

-- Track state internally
local transparency_enabled = true

local function toggle_transparency()
  transparency_enabled = not transparency_enabled

  require("catppuccin").setup {
    transparent_background = transparency_enabled,
  }

  vim.cmd "colorscheme catppuccin"

  vim.notify("Transparency " .. (transparency_enabled and "Enabled" or "Disabled"), vim.log.levels.INFO, { title = "Catppuccin" })
end

keymap.set("n", "<leader>bg", toggle_transparency, { desc = "Toggle background transparency" })
