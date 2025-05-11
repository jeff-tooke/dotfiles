vim.g.mapleader = " "

local keymap = vim.keymap

-- Optimise switching between modes
keymap.set("i", "jj", "<ESC>", { desc = "Exit insert mode with jj" })
keymap.set("n", "jk", "i", { desc = "Enter insert mode with jk" })
keymap.set("n", ";", ":", { desc = "Enter command mode with ;" })

-- Get that muscle memory going;
keymap.set({ 'n', 'v' }, '<Up>', function() print("Use 'k' instead 🤓") end, opts)
keymap.set({ 'n', 'v' }, '<Down>', function() print("Use 'j' instead 🤓") end, opts)
keymap.set({ 'n', 'v' }, '<Left>', function() print("Use 'h' instead 🤓") end, opts)
keymap.set({ 'n', 'v' }, '<Right>', function() print("Use 'l' instead 🤓") end, opts)

-- Custom stuff
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

