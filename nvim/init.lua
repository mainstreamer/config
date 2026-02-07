-- Standard mode detection
-- Set NVIM_STANDARD=1 or create ~/.config/nvim/.standard to enable
local standard = os.getenv("NVIM_STANDARD") == "1" or
    vim.fn.filereadable(vim.fn.expand("~/.config/nvim/.standard")) == 1
if standard then
    require('config.lazy-standard')
    return
end

-- yank to system clipboard by default
vim.opt.clipboard = "unnamedplus"

-- Map <Esc> to exit Terminal mode and enter Normal mode
vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true })

-- Show errors in popup window
vim.keymap.set("n", "<C-k>", vim.diagnostic.open_float, { desc = "Line Diagnostics" })

-- Add relative line numbers
vim.opt.relativenumber = true
vim.opt.number = true

vim.g.mapleader = " " -- Set space as leader
vim.o.background = "dark"

-- PHP code fixer
vim.api.nvim_set_keymap('n', '<leader>fix', ':!phpcbf %<CR>', { noremap = true, silent = true })

require('config.lazy')
