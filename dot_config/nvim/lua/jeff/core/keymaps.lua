vim.g.mapleader = " "

local keymap = vim.keymap

-- Optimise switching between modes
keymap.set("i", "jj", "<ESC>", { desc = "Exit insert mode with jj" })
keymap.set("n", "jk", "i", { desc = "Enter insert mode with jk" })
-- keymap.set("n", ";", ":", { desc = "Enter command mode with ;" })

-- Get that muscle memory going;
keymap.set({ "n", "v" }, "<Up>", function()
  print "Use 'k' instead 🤓"
end, opts)
keymap.set({ "n", "v" }, "<Down>", function()
  print "Use 'j' instead 🤓"
end, opts)
keymap.set({ "n", "v" }, "<Left>", function()
  print "Use 'h' instead 🤓"
end, opts)
keymap.set({ "n", "v" }, "<Right>", function()
  print "Use 'l' instead 🤓"
end, opts)

-- Custom stuff
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })
keymap.set("t", "<ESC>", [[<C-\><C-n>]], { desc = "Exit out of terminal mode" })
keymap.set("n", "<leader>w", ":w<CR>", { noremap = true, silent = true, desc = "Save buffer" })
keymap.set("n", "<leader>q", ":wqa<CR>", { noremap = true, silent = true, desc = "Save and exit all buffers" })
keymap.set("n", "<leader>x", ":qa!<CR>", { noremap = true, silent = true, desc = "Force quit all!" })
keymap.set("n", "<leader><left>", ":bp<CR>", { noremap = true, silent = true, desc = "Previous buffer" })
keymap.set("n", "<leader><right>", ":bn<CR>", { noremap = true, silent = true, desc = "Next buffer" })

-- Track state internally
local transparency_enabled = false

local function toggle_transparency()
  transparency_enabled = not transparency_enabled

  require("catppuccin").setup {
    transparent_background = transparency_enabled,
  }

  vim.cmd "colorscheme catppuccin"

  -- Optional: clear backgrounds of other groups
  if transparency_enabled then
    local groups = {
      "NormalNC",
      "NvimTreeNormal",
      "TelescopeNormal",
      "TelescopeBorder",
      "FloatBorder",
      "Pmenu",
      "StatusLine",
      "StatusLineNC",
    }
    for _, group in ipairs(groups) do
      vim.api.nvim_set_hl(0, group, { bg = "none" })
    end
  end

  vim.notify("Transparency " .. (transparency_enabled and "Enabled" or "Disabled"), vim.log.levels.INFO, { title = "Catppuccin" })
end

keymap.set("n", "<leader>bg", toggle_transparency, { desc = "Toggle background transparency" })
