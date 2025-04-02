require('config.lazy')

-- yank to system clipboard by default
vim.opt.clipboard = "unnamedplus"

-- Map <Esc> to exit Terminal mode and enter Normal mode
vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true })

-- Add relative line numbers
vim.opt.relativenumber = true
vim.opt.number = true

-- Variables to track terminal buffer and window
local terminal_bufnr = nil
local terminal_winid = nil

vim.g.mapleader = " " -- Set space as leader
vim.o.background = "dark"
