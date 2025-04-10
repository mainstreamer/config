-- Just for my personal knowledge
-- Lazyvim manages plugins - it downloads and istalls it
-- To enable plugin it should be required and setup method called

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

local plugins = {
	{
		'neovim/nvim-lspconfig',  -- LSP Config plugin
		config = function()
			local lspconfig = require("lspconfig")
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

			lspconfig.phpactor.setup({
        capabilities = capabilities,
				root_dir = lspconfig.util.root_pattern("composer.json", ".git", "index.php"),
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
      --end,
    -- ts_ls (for TypeScript, Node.js, React)
    lspconfig.ts_ls.setup({
      capabilities = capabilities,
      root_dir = lspconfig.util.root_pattern("tsconfig.json", "package.json", ".git"),
      on_attach = function(client, bufnr)
        -- Disable formatting for ts_ls as we will use eslint for formatting
        client.server_capabilities.document_formatting = false

        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
      end,
    })

    -- eslint (for linting and fixing issues in JavaScript/TypeScript/React)
    lspconfig.eslint.setup({
      capabilities = capabilities,
      root_dir = lspconfig.util.root_pattern(".eslintrc.js", ".eslintrc.json", "package.json", ".git"),
      cmd = { "eslint-lsp", "--stdio" },
        on_attach = function(client, bufnr)
        -- Enable eslint formatting
        client.server_capabilities.document_formatting = true

        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
      end,
    })

      -- Golang (gopls)
      lspconfig.gopls.setup({
        capabilities = capabilities,
        root_dir = lspconfig.util.root_pattern("go.mod", ".git"),
        cmd = { "gopls" },
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

	-- Install vim-zettel for Zettelkasten-style note-taking
	--  TODO figure out how to use it - TOO COMPLEX NEEDS LEARNING MAYBE DELETE IT?
	{
		'michal-h21/vim-zettel',
		config = function()
			-- Any additional configuration for vim-zettel goes here
			-- For example, setting up the directory where notes are stored
			vim.g.zettel_directory = '~/Projects/notes'  -- Set the directory for your notes
			vim.g.zettel_extension = '.md'  -- You can change the file extension, e.g., `.txt` or `.org`
		end,
	},


  "williamboman/mason.nvim", -- golang lsp ???
  "williamboman/mason-lspconfig.nvim", -- Mason-lspconfig - golang autocompletin and checks
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
	-- {
	-- 	"EdenEast/nightfox.nvim",
	-- 	lazy = false, -- Load during startup
	-- 	priority = 1000, -- Ensure it loads before other plugins
	-- 	config = function()
	-- 		vim.cmd("colorscheme carbonfox") -- Set Tokyo Night as the colorscheme
	-- 	end,
	-- },
-- Treesitter for better syntax highlighting
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "javascript", "python", "lua", "php", "html", "css", "rust", "go", "c", "ruby" },
				highlight = { enable = true, additional_vim_regex_highlighting = true },
				-- TODO WTF is this?
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "gnn",
						node_incremental = "grn",
						node_decremental = "grm",
					},
				},
				indent = { enable = true },
				rainbow = {
					enable = true,
					extended_mode = true,
				}
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
    event = "VimEnter", -- This makes sure it's loaded when Neovim starts
		config = function()
			vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>", { noremap = true, silent = true })
			vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>", { noremap = true, silent = true })
			vim.keymap.set("n", "<leader>fb", ":Telescope buffers<CR>", { noremap = true, silent = true })
			vim.keymap.set("n", "<leader>fh", ":Telescope help_tags<CR>", { noremap = true, silent = true })
			vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, { noremap = true, silent = true })
		end,
	},

	{
		"nvim-tree/nvim-tree.lua",
		config = function()
			-- Set up nvim-tree with valid options
			require("nvim-tree").setup({
				-- Core settings
				auto_reload_on_write = true,  -- Reload tree automatically when file is saved
				update_cwd = true,           -- Update the working directory when opening a file
				update_focused_file = {
					enable = true,             -- Update the focused file automatically
					update_cwd = true,
				},

				-- View settings
				view = {
					width = 30,                -- Width of the tree
					side = "left",             -- Position of the tree (left or right)
					number = false,            -- Disable line numbers in the file tree
					relativenumber = false,    -- Disable relative line numbers
				},

				-- Git integration
				git = {
					enable = true,             -- Show git status in the tree
					ignore = false,            -- Don't ignore untracked files
				},

				-- File filters
				filters = {
					dotfiles = false,          -- Don't hide dotfiles by default
				},

				-- Actions
				actions = {
					open_file = {
						quit_on_open = false,     -- Keep nvim-tree open when opening a file
					},
				},
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

	-- TODO - maybe delet? I use tabline for that 
	-- Harpoon (Fast File Navigation) - bind buffers to hotkeys
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function() 
			require("harpoon").setup()
		end
	},

	-- Bufferline (Tab-like Buffer Display)
	{
		"akinsho/bufferline.nvim",
		dependencies = "nvim-tree/nvim-web-devicons",
		config = function()
			require("bufferline").setup({
				options = {
					numbers = "ordinal", -- show buffer number
					diagnostics = "nvim_lsp",
					show_buffer_close_icons = false,
					show_close_icon = false,
					separator_style = "slant",
				},
			})
		end
	},

	-- TODO - how to use it?
	{ 'tpope/vim-commentary' },

	-- GIT BLAME!
	{ 'lewis6991/gitsigns.nvim',
		config = function()
			require('gitsigns').setup {
				signs = {
					add          = { text = '▍' },
					change       = { text = '▍' },
					delete       = { text = '▍' },
					topdelete    = { text = '▍' },
					changedelete = { text = '▍' },
				},
				current_line_blame = true,  -- This will show blame inline as virtual text
				current_line_blame_opts = {
					virt_text = true,          -- Display blame as virtual text
					virt_text_pos = 'eol',     -- Position it at the end of the line
					delay = 100,               -- Optional: delay in milliseconds before showing blame
				},
				keymaps = {
					noremap = true,
					buffer = true,
					-- ['n <leader>gh'] = { expr = true, "&diff ? 'diffget //2' : 'GitGutter'"},
				},
			}
		end,
	},
	-- TODO how to use it?
	{
		'tpope/vim-surround',  -- Add this line
		config = function()
			-- Optional: Custom configuration for vim-surround
		end,
	}
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
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
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

vim.opt.tabstop = 2        -- Number of spaces that a tab represents
vim.opt.shiftwidth = 2     -- Number of spaces used for auto-indentation
vim.opt.expandtab = true   -- Convert tabs to spaces
vim.opt.smartindent = true -- Enable smart indentation
vim.opt.autoindent = true  -- Maintain indentation from the previous line
vim.opt.smarttab = true    -- Use intelligent tabbing

vim.opt.list = true
vim.opt.listchars = {
	tab = "▸ ", -- Display tabs with an arrow
	trail = "·", -- Show trailing spaces
	extends = ">", -- Indicate wrapped text beyond the right margin
	precedes = "<", -- Indicate text that wraps before the left margin
}

-- yank to system clipboard by default
vim.opt.clipboard = "unnamedplus"

-- Key bindings for commenting code
vim.api.nvim_set_keymap("n", "<C-_>", "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>", { noremap = true, silent = true }) -- Normal mode
vim.api.nvim_set_keymap("v", "<C-_>", "<cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", { noremap = true, silent = true }) -- Visual mode

-- Key bindings for Harpoon
local harpoon = require("harpoon")

-- Add current file to Harpoon
vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)

-- Open Harpoon menu (Shows the list of marked files)
vim.keymap.set("n", "<leader>h", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

-- Navigate between Harpoon files
vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end)
vim.keymap.set("n", "<leader>5", function() harpoon:list():select(5) end)
vim.keymap.set("n", "<leader>6", function() harpoon:list():select(6) end)

-- Cycle through buffers (Bufferline)
vim.keymap.set("n", "<Tab>", ":BufferLineCycleNext<CR>", { silent = true })
vim.keymap.set("n", "<S-Tab>", ":BufferLineCyclePrev<CR>", { silent = true })
vim.keymap.set("n", "<A-q>", ":bd<CR>", { silent = true }) -- Close current buffer

-- Use Alt+1, Alt+2, ... to switch to buffer 1, buffer 2, ...
vim.api.nvim_set_keymap('n', '<A-1>', ':BufferLineGoToBuffer 1<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<A-2>', ':BufferLineGoToBuffer 2<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<A-3>', ':BufferLineGoToBuffer 3<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<A-4>', ':BufferLineGoToBuffer 4<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<A-5>', ':BufferLineGoToBuffer 5<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<A-6>', ':BufferLineGoToBuffer 6<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<A-7>', ':BufferLineGoToBuffer 7<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<A-8>', ':BufferLineGoToBuffer 8<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<A-9>', ':BufferLineGoToBuffer 9<CR>', { noremap = true, silent = true })

-- TODO WTF? ZETTLE NOTES Create a new note
vim.keymap.set('n', '<leader>zn', ':ZettelCreate<CR>', { noremap = true, silent = true })
-- Open note from ID or title
vim.keymap.set('n', '<leader>zo', ':ZettelOpen<CR>', { noremap = true, silent = true })

-- Disable netrw (optional, recommended for preventing conflicts)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Keybinding for opening/closing nvim-tree
vim.api.nvim_set_keymap('n', '<C-n>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })


-- Set GitSigns highlights
vim.api.nvim_set_hl(0, 'GitSignsAdd', { link = 'GitSignsAdd' })
vim.api.nvim_set_hl(0, 'GitSignsChange', { link = 'GitSignsChange' })
vim.api.nvim_set_hl(0, 'GitSignsDelete', { link = 'GitSignsDelete' })
vim.api.nvim_set_hl(0, 'GitSignsTopdelete', { link = 'GitSignsDelete' })
vim.api.nvim_set_hl(0, 'GitSignsChangedelete', { link = 'GitSignsChangeDelete' })

-- Set up GitSigns keymaps
vim.keymap.set('n', '<leader>gs', '<cmd>Gitsigns stage_hunk<cr>', { noremap = true })
vim.keymap.set('n', '<leader>gr', '<cmd>Gitsigns reset_hunk<cr>', { noremap = true })
vim.keymap.set('n', '<leader>gp', '<cmd>Gitsigns preview_hunk<cr>', { noremap = true })
vim.keymap.set('n', '<leader>gn', '<cmd>Gitsigns next_hunk<cr>', { noremap = true })
vim.keymap.set('n', '<leader>gp', '<cmd>Gitsigns prev_hunk<cr>', { noremap = true })

-- Optional: Set up custom highlights for blame information (if desired)
vim.api.nvim_set_hl(0, 'GitSignsBlame', { fg = '#D4D4D4' })  -- Example highlight color

-- Keymap to show blame for the current line
vim.keymap.set('n', '<leader>gb', function()
	require('gitsigns').blame_line({full=true})
end)

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


