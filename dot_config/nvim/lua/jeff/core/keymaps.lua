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
keymap.set("i", "<Up>", '<Esc>:echo "Use k"<CR>a', opts)
keymap.set("i", "<Down>", '<Esc>:echo "Use j"<CR>a', opts)
keymap.set("i", "<Left>", '<Esc>:echo "Use h"<CR>a', opts)
keymap.set("i", "<Right>", '<Esc>:echo "Use l"<CR>a', opts)

-- Custom stuff
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })
keymap.set("t", "<ESC>", [[<C-\><C-n>]], { desc = "Exit out of terminal mode" })
keymap.set("n", "<leader>w", ":w<CR>", { noremap = true, silent = true, desc = "Save buffer" })
keymap.set("n", "<leader>q", ":wqa<CR>", { noremap = true, silent = true, desc = "Save and exit all buffers" })
keymap.set("n", "<leader>x", ":qa!<CR>", { noremap = true, silent = true, desc = "Force quit all!" })
keymap.set("n", "<leader><left>", ":bp<CR>", { noremap = true, silent = true, desc = "Previous buffer" })
keymap.set("n", "<leader><right>", ":bn<CR>", { noremap = true, silent = true, desc = "Next buffer" })
keymap.set("n", "<leader>ca", ":up <bar> %bd <bar> e# <bar> bd# <CR>", { noremap = true, silent = true, desc = "Update and close all buffers except current" })

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
