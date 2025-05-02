vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
keymap.set("n", "jj", "i", { desc = "Enter insert mode with jj" })
keymap.set("n", ";", ":", { desc = "Enter command mode with ;" })
--keymap.set("n", ":", ";", { desc = "Enter command mode with ;" })

-- Get that muscle memory going;
keymap.set({ 'n', 'v' }, '<Up>', function() print("Use 'k' instead 🤓") end, opts)
keymap.set({ 'n', 'v' }, '<Down>', function() print("Use 'j' instead 🤓") end, opts)
keymap.set({ 'n', 'v' }, '<Left>', function() print("Use 'h' instead 🤓") end, opts)
keymap.set({ 'n', 'v' }, '<Right>', function() print("Use 'l' instead 🤓") end, opts)
--keymap.set('i', '<Up>', function() print("Use 'k' instead 🤓") end, opts)
--keymap.set('i', '<Down>', function() print("Use 'j' instead 🤓") end, opts)
--keymap.set('i', '<Left>', function() print("Use 'h' instead 🤓") end, opts)
--keymap.set('i', '<Right>', function() print("Use 'l' instead 🤓") end, opts)


keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

