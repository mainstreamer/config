-- Standard Neovim configuration
-- Excludes LSP, autocompletion, and language-specific tooling
-- Use --dev mode install for full developer environment

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

local plugins = {
	-- Theme
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd("colorscheme tokyonight")
		end,
	},

	-- Treesitter (minimal languages)
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local parsers = { "lua", "bash", "json", "yaml", "markdown", "vim", "vimdoc" }

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
					highlight = { enable = true },
					indent = { enable = true },
				})
			end
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
			telescope.load_extension("fzf")

			vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>", { noremap = true, silent = true })
			vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>", { noremap = true, silent = true })
			vim.keymap.set("n", "<leader>fb", ":Telescope buffers<CR>", { noremap = true, silent = true })
			vim.keymap.set("n", "<leader>fh", ":Telescope help_tags<CR>", { noremap = true, silent = true })
		end,
	},

	-- File tree
	{
		"nvim-tree/nvim-tree.lua",
		config = function()
			require("nvim-tree").setup({
				auto_reload_on_write = true,
				update_cwd = true,
				update_focused_file = {
					enable = true,
					update_cwd = true,
				},
				view = {
					width = 30,
					side = "left",
					number = false,
					relativenumber = false,
				},
				git = {
					enable = true,
					ignore = false,
				},
				filters = {
					dotfiles = false,
				},
				actions = {
					open_file = {
						quit_on_open = false,
					},
				},
			})
		end,
	},

	-- Status line
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup()
		end,
	},

	-- Git signs
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "▍" },
					change = { text = "▍" },
					delete = { text = "▍" },
					topdelete = { text = "▍" },
					changedelete = { text = "▍" },
				},
				current_line_blame = true,
				current_line_blame_opts = {
					virt_text = true,
					virt_text_pos = "eol",
					delay = 100,
				},
				on_attach = function(bufnr)
					local gs = require("gitsigns")
					local function map(mode, lhs, rhs, opts)
						opts = opts or { buffer = bufnr }
						vim.keymap.set(mode, lhs, rhs, opts)
					end
					map("n", "<leader>gs", gs.stage_hunk)
					map("n", "<leader>gr", gs.reset_hunk)
					map("n", "<leader>gp", gs.preview_hunk)
					map("n", "<leader>gb", gs.blame_line)
					map("n", "<leader>gd", gs.diffthis)
				end,
			})
		end,
	},

	-- Comment code
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},

	-- Bufferline
	{
		"akinsho/bufferline.nvim",
		dependencies = "nvim-tree/nvim-web-devicons",
		config = function()
			require("bufferline").setup({
				options = {
					numbers = "ordinal",
					show_buffer_close_icons = false,
					show_close_icon = false,
					separator_style = "slant",
				},
			})
		end,
	},

	-- Surround
	{ "tpope/vim-surround" },

	-- Which-key
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			require("which-key").setup({})
		end,
	},

	-- Auto-pairs
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup({})
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

	-- Toggleterm
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		keys = {
			{ "ttt", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Toggle Terminal" },
			{ "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Floating Terminal" },
			{ "<leader>tv", "<cmd>ToggleTerm direction=vertical size=80<cr>", desc = "Vertical Terminal" },
			{
				"<leader>tg",
				function()
					local Terminal = require("toggleterm.terminal").Terminal
					local lazygit = Terminal:new({ cmd = "lazygit", hidden = true, direction = "float" })
					lazygit:toggle()
				end,
				desc = "Lazygit",
			},
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
				open_mapping = nil,
				shade_terminals = true,
				shading_factor = 2,
				start_in_insert = true,
				persist_size = true,
				persist_mode = true,
				close_on_exit = true,
			})

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
}

require("lazy").setup(plugins, {})

-- Editor settings
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.smarttab = true

vim.opt.list = true
vim.opt.listchars = {
	tab = "▸ ",
	trail = "·",
	extends = ">",
	precedes = "<",
}

-- Key bindings for commenting code
vim.api.nvim_set_keymap(
	"n",
	"<C-_>",
	"<cmd>lua require('Comment.api').toggle.linewise.current()<CR>",
	{ noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
	"v",
	"<C-_>",
	"<cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
	{ noremap = true, silent = true }
)

-- Cycle through buffers
vim.keymap.set("n", "<Tab>", ":BufferLineCycleNext<CR>", { silent = true })
vim.keymap.set("n", "<S-Tab>", ":BufferLineCyclePrev<CR>", { silent = true })
vim.keymap.set("n", "<A-q>", ":bd<CR>", { silent = true })

-- Buffer switching with Alt+number
for i = 1, 9 do
	vim.api.nvim_set_keymap(
		"n",
		"<A-" .. i .. ">",
		":BufferLineGoToBuffer " .. i .. "<CR>",
		{ noremap = true, silent = true }
	)
end

-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Nvim-tree toggle
vim.api.nvim_set_keymap("n", "<C-n>", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
