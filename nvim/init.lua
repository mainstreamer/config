-- Minimal mode detection
-- Set NVIM_MINIMAL=1 or create ~/.config/nvim/.minimal to enable
local minimal = os.getenv("NVIM_MINIMAL") == "1" or
    vim.fn.filereadable(vim.fn.expand("~/.config/nvim/.minimal")) == 1
if minimal then
    require('config.lazy-minimal')
    return
end

-- yank to system clipboard by default
vim.opt.clipboard = "unnamedplus"

-- Map <Esc> to exit Terminal mode and enter Normal mode
vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true })

-- Show erorrs in popup window
vim.keymap.set("n", "<C-k>", vim.diagnostic.open_float, { desc = "Line Diagnostics" })

-- Add relative line numbers
vim.opt.relativenumber = true
vim.opt.number = true

vim.g.mapleader = " " -- Set space as leader
vim.o.background = "dark"

-- PHP code fixer
vim.api.nvim_set_keymap('n', '<leader>fix', ':!phpcbf %<CR>', { noremap = true, silent = true })

require('config.lazy')

-- Variables to track terminal buffer and window
local terminal_bufnr = nil
local terminal_winid = nil

