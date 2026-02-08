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
    -- Mason: LSP server installer (use :MasonInstall to install servers)
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = true,
  },
  -- NOTE: mason-lspconfig removed - not needed with Neovim 0.11+ vim.lsp.config API
  -- Use :MasonInstall pyright (etc.) to install servers manually

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
			local parsers = { "javascript", "python", "lua", "php", "html", "css", "rust", "go", "c", "ruby" }

			-- New API (nvim-treesitter 1.0+)
			local ok, ts = pcall(require, "nvim-treesitter")
			if ok and type(ts.install) == "function" then
				pcall(ts.setup)
				pcall(ts.install, parsers)
				vim.api.nvim_create_autocmd("FileType", {
					group = vim.api.nvim_create_augroup("ts-highlight", { clear = true }),
					callback = function(ev)
						pcall(vim.treesitter.start, ev.buf)
					end,
				})
				return
			end

			-- Legacy API (nvim-treesitter < 1.0)
			local ok2, configs = pcall(require, "nvim-treesitter.configs")
			if ok2 then
				configs.setup({
					ensure_installed = parsers,
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
					rainbow = {
						enable = true,
						extended_mode = true,
					}
				})
			end
		end,
	},

	-- null-ls setup for formatters and linters (using none-ls, the maintained fork)
	{
		"nvimtools/none-ls.nvim",
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
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		event = "VimEnter",
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				extensions = {
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
						case_mode = "smart_case",
					},
				},
			})
			-- Load fzf extension for faster sorting
			telescope.load_extension("fzf")

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
        on_attach = function(bufnr)
        local gs = require('gitsigns')

        -- Keymap helper function
        local function map(mode, lhs, rhs, opts)
          opts = opts or { buffer = bufnr }
          vim.keymap.set(mode, lhs, rhs, opts)
        end
          -- Set keymaps
          map('n', '<leader>gs', gs.stage_hunk)
          map('n', '<leader>gr', gs.reset_hunk)
          map('n', '<leader>gp', gs.preview_hunk)
          map('n', '<leader>gb', gs.blame_line)
          map('n', '<leader>gd', gs.diffthis)
       end,
			}
		end,
	},
	-- Surround: cs'" to change 'x' to "x", ysiw) to surround word with ()
	{ 'tpope/vim-surround' },

	-- Which-key: shows keybinding hints
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			require("which-key").setup({})
		end,
	},

	-- Trouble: better diagnostics list
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		cmd = "Trouble",
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
			{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
			{ "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
			{ "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
		},
		config = function()
			require("trouble").setup({})
		end,
	},

	-- Auto-pairs: auto-close brackets and quotes
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup({})
			-- Integrate with nvim-cmp
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			local cmp = require("cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},

	-- Indent guides
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("ibl").setup({
				indent = { char = "│" },
				scope = { enabled = true },
			})
		end,
	},

	-- TODO comments highlighting
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("todo-comments").setup({})
		end,
		keys = {
			{ "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
		},
	},

	-- Diffview: better git diff/merge UI
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewFileHistory" },
		keys = {
			{ "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Git Diffview" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File Git History" },
		},
		config = function()
			require("diffview").setup({})
		end,
	},

	-- Toggleterm: better terminal management
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		keys = {
			{ "ttt", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Toggle Terminal" },
			{ "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Floating Terminal" },
			{ "<leader>tv", "<cmd>ToggleTerm direction=vertical size=80<cr>", desc = "Vertical Terminal" },
			{ "<leader>tg", function()
				local Terminal = require("toggleterm.terminal").Terminal
				local lazygit = Terminal:new({ cmd = "lazygit", hidden = true, direction = "float" })
				lazygit:toggle()
			end, desc = "Lazygit" },
		},
		config = function()
			require("toggleterm").setup({
				size = function(term)
					if term.direction == "horizontal" then
						return 15
					elseif term.direction == "vertical" then
						return vim.o.columns * 0.4
					end
				end,
				open_mapping = nil, -- We use custom keymaps
				shade_terminals = true,
				shading_factor = 2,
				start_in_insert = true,
				persist_size = true,
				persist_mode = true,
				close_on_exit = true,
			})

			-- Terminal mode mappings (escape to normal mode)
			function _G.set_terminal_keymaps()
				local opts = { buffer = 0 }
				vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
				vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
				vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
				vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
				vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
			end
			vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
		end,
	},

  { import = "plugins" }
}

-- Autoformat Rust files
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.rs",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})


require("lazy").setup(plugins, {})

-- ============================================================================
-- LSP Configuration (Neovim 0.11+ built-in API, no nvim-lspconfig needed)
-- ============================================================================

-- Set default capabilities for all LSP servers (from cmp_nvim_lsp)
vim.lsp.config('*', {
	capabilities = require('cmp_nvim_lsp').default_capabilities(),
})

-- PHP (phpactor)
vim.lsp.config.phpactor = {
	cmd = { "phpactor", "language-server" },
	filetypes = { "php" },
	root_markers = { "composer.json", ".git", "index.php" },
}

-- TypeScript/JavaScript (ts_ls)
vim.lsp.config.ts_ls = {
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	root_markers = { "tsconfig.json", "package.json", ".git" },
}

-- ESLint
vim.lsp.config.eslint = {
	cmd = { "eslint-lsp", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	root_markers = { ".eslintrc.js", ".eslintrc.json", "eslint.config.js", "package.json", ".git" },
}

-- Golang (gopls)
vim.lsp.config.gopls = {
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	root_markers = { "go.mod", ".git" },
	settings = {
		gopls = {
			gofumpt = true,
			staticcheck = true,
		},
	},
}

-- Python (pyright)
vim.lsp.config.pyright = {
	filetypes = { "python" },
	root_markers = { "pyproject.toml", "setup.py", "requirements.txt", ".git" },
}

-- Enable all configured LSP servers
vim.lsp.enable({ 'phpactor', 'ts_ls', 'eslint', 'gopls', 'pyright' })

-- Global LSP keymaps via LspAttach autocmd
vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(args)
		local bufnr = args.buf
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local bufopts = { noremap = true, silent = true, buffer = bufnr }

		-- Disable formatting for ts_ls (use eslint instead)
		if client and client.name == 'ts_ls' then
			client.server_capabilities.documentFormattingProvider = false
		end

		-- LSP keymaps
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
	end,
})

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

-- Disable netrw (optional, recommended for preventing conflicts)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Keybinding for opening/closing nvim-tree
vim.api.nvim_set_keymap('n', '<C-n>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })



