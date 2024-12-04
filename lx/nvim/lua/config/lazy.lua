local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " " -- the leader key is used in many keymaps, 

local plugins = {
    -- plugins go here

-- LSP support for Python and other languages
    "neovim/nvim-lspconfig",

    -- Autocompletion and snippets
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-nvim-lsp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",

    -- Theme
    {
        "folke/tokyonight.nvim",
        lazy = false, -- Load during startup
    priority = 1000, -- Ensure it loads before other plugins
        config = function()
            vim.cmd("colorscheme tokyonight") -- Set Tokyo Night as the colorscheme
        end,
    },
    -- Treesitter for better syntax highlighting
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = { "javascript", "python", "lua", "php", "html", "css" },
                highlight = { enable = true, additional_vim_regex_highlighting = true },
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "gnn",
                        node_incremental = "grn",
                        node_decremental = "grm",
                    },
                },
                indent = { enable = true },
            })
        end,
    },

    -- null-ls setup for formatters and linters
    {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
            local null_ls = require("null-ls")
            null_ls.setup({
                sources = {
                    null_ls.builtins.formatting.black,
                    null_ls.builtins.diagnostics.phpcs,
                    null_ls.builtins.formatting.phpcsfixer,
                },
            })
        end,
    },

    -- Telescope for fuzzy finding
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>", { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>", { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>fb", ":Telescope buffers<CR>", { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>fh", ":Telescope help_tags<CR>", { noremap = true, silent = true })
            vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, { noremap = true, silent = true })
        end,
    },

    -- File explorer NERDTree
    {
        "preservim/nerdtree",
        cmd = "NERDTreeToggle",
        config = function()
            vim.api.nvim_set_keymap("n", "<leader>n", ":NERDTreeToggle<CR>", { noremap = true, silent = true })
        end,
    },
 
    -- Git signs
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup()
        end,
    },

    -- PHP Language Server (Phpactor)
    {
        "phpactor/phpactor",
        config = function()
            local lspconfig = require("lspconfig")
            lspconfig.phpactor.setup({
                cmd = { "phpactor", "language-server" },
                on_attach = function(client, bufnr)
                    local bufopts = { noremap = true, silent = true, buffer = bufnr }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
                end,
            })
        end,
    },

    -- Python-specific indenting
    "Vimjas/vim-python-pep8-indent",

    -- Status line
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require("lualine").setup()
        end,
    },

    -- Comment code
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
        end,
    },
}


require("lazy").setup(plugins, {})



-- Autocompletion setup
local cmp = require("cmp")
cmp.setup({
    snippet = {
        expand = function(args)
            require("luasnip").lsp_expand(args.body)
        end,
    },
    mapping = {
        ["<Tab>"] = cmp.mapping.select_next_item(),
        ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
    },
    sources = {
        { name = "nvim_lsp" },
        { name = "buffer" },
        { name = "path" },
    },
})


-- Keybindings for LSP actions
vim.api.nvim_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", { noremap = true, silent = true })
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        if #vim.fn.argv() == 0 then
            vim.cmd("NERDTree")
        end
    end,
})

vim.opt.tabstop = 4        -- Number of spaces that a tab represents
vim.opt.shiftwidth = 4     -- Number of spaces used for auto-indentation
vim.opt.expandtab = true   -- Convert tabs to spaces
vim.opt.smartindent = true -- Enable smart indentation
vim.opt.autoindent = true  -- Maintain indentation from the previous line

vim.opt.list = true
vim.opt.listchars = {
    tab = "▸ ", -- Display tabs with an arrow
    trail = "·", -- Show trailing spaces
    extends = ">", -- Indicate wrapped text beyond the right margin
    precedes = "<", -- Indicate text that wraps before the left margin
}

-- yank to system clipboard by default
-- vim.opt.clipboard = "unnamedplus"

-- Map <Esc> to exit Terminal mode and enter Normal mode
-- vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true })


-- Variables to track terminal buffer and window
-- local terminal_bufnr = nil
-- local terminal_winid = nil

-- Keybinding to toggle terminal
-- vim.api.nvim_set_keymap("n", "<leader>t", ":lua ToggleTerminal()<CR>", { noremap = true, silent = true })

-- Toggle Terminal Function
-- function ToggleTerminal()
--     if terminal_winid and vim.api.nvim_win_is_valid(terminal_winid) then
--         -- If terminal is open, close it
--         -- vim.api.nvim_win_hide(terminal_winid)
--          vim.api.nvim_win_close(terminal_winid, true) -- Close the terminal window
--         terminal_winid = nil
--     else
--         -- Create the terminal buffer if it doesn't exist
--         if not terminal_bufnr or not vim.api.nvim_buf_is_valid(terminal_bufnr) then
--             terminal_bufnr = vim.api.nvim_create_buf(false, true) -- Create an unlisted buffer
--             vim.api.nvim_buf_set_option(terminal_bufnr, "bufhidden", "wipe") -- Automatically clean buffer
--         end
--
--         -- Open a horizontal split at the bottom
--         vim.cmd("botright split")
--         vim.cmd("resize 10") -- Set the height of the terminal to 10 lines
--         terminal_winid = vim.api.nvim_get_current_win() -- Get the current window ID
--
--         -- Set the terminal buffer in the new window and start a terminal
--         vim.api.nvim_win_set_buf(terminal_winid, terminal_bufnr)
--         vim.fn.termopen(vim.o.shell) -- Open a shell in the terminal
--         vim.cmd("startinsert") -- Enter terminal insert mode
--     end
-- end

-- Key bindings for commenting code
vim.api.nvim_set_keymap("n", "<C-_>", "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>", { noremap = true, silent = true }) -- Normal mode
vim.api.nvim_set_keymap("v", "<C-_>", "<cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", { noremap = true, silent = true }) -- Visual mode

