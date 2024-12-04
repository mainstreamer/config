require('config.lazy')

-- yank to system clipboard by default
vim.opt.clipboard = "unnamedplus"

-- Map <Esc> to exit Terminal mode and enter Normal mode
vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true })


-- Variables to track terminal buffer and window
local terminal_bufnr = nil
local terminal_winid = nil

-- Keybinding to toggle terminal
vim.api.nvim_set_keymap("n", "ttt", ":lua ToggleTerminal()<CR>", { noremap = true, silent = true })

-- Toggle Terminal Function
function ToggleTerminal()
    if terminal_winid and vim.api.nvim_win_is_valid(terminal_winid) then
        -- If terminal is open, close it
        -- vim.api.nvim_win_hide(terminal_winid)
         vim.api.nvim_win_close(terminal_winid, true) -- Close the terminal window
        terminal_winid = nil
    else
        -- Create the terminal buffer if it doesn't exist
        if not terminal_bufnr or not vim.api.nvim_buf_is_valid(terminal_bufnr) then
            terminal_bufnr = vim.api.nvim_create_buf(false, true) -- Create an unlisted buffer
            vim.api.nvim_buf_set_option(terminal_bufnr, "bufhidden", "wipe") -- Automatically clean buffer
        end

        -- Open a horizontal split at the bottom
        vim.cmd("botright split")
        vim.cmd("resize 10") -- Set the height of the terminal to 10 lines
        terminal_winid = vim.api.nvim_get_current_win() -- Get the current window ID

        -- Set the terminal buffer in the new window and start a terminal
        vim.api.nvim_win_set_buf(terminal_winid, terminal_bufnr)
        vim.fn.termopen(vim.o.shell) -- Open a shell in the terminal
        vim.cmd("startinsert") -- Enter terminal insert mode
    end
end

-- Show all files
vim.g.NERDTreeShowHidden = 1

