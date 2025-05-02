vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt

opt.relativenumber = true
opt.number = true
opt.cursorline = true

-- tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- search settings
opt.ignorecase = true
opt.smartcase = true

-- ui
opt.termguicolors = true
opt.wrap = false
opt.scrolloff  = 8

-- backspace
opt.backspace = "indent,eol,start"

-- clipboard
opt.clipboard:append("unnamedplus")

-- splits
opt.splitright = true
opt.splitbelow = true

-- swapfile
opt.swapfile = false
