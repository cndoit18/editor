local tools = {
	-- Formatter
	"delve",
	"stylua",
	"sqlfmt",
	"shfmt",
	"gofumpt",
	"prettier",

	-- Lint
	"markdownlint",
	"golangci-lint",

	-- All
	"ruff",
}

local lsp_servers = {
	"rust_analyzer",
	"bashls",
	"dockerls",
	"jsonls",
	"gopls",
	"helm_ls",
	"pyright",
	"lua_ls",
	"yamlls",
}

return {
	{
		"rcarriga/nvim-notify",
	},

	{
		"mfussenegger/nvim-dap",
		lazy = true,
		keys = {
			{ "<leader>d", "", desc = "+Debug" },
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle Breakpoint",
			},
			{
				"<leader>dc",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "Continue",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "Step Into",
			},
			{
				"<leader>dn",
				function()
					require("dap").step_over()
				end,
				desc = "Step Over",
			},
			{
				"<leader>do",
				function()
					require("dap").step_out()
				end,
				desc = "Step Out",
			},
			{
				"<leader>du",
				function()
					require("dap").up()
				end,
				desc = "Up",
			},
			{
				"<leader>dr",
				function()
					require("dap").repl.toggle()
				end,
				desc = "Toggle REPL",
			},
			{
				"<leader>ds",
				function()
					require("dap").continue()
				end,
				desc = "Run",
			},
			{
				"<leader>dC",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "Run to Cursor",
			},
			{
				"<leader>dl",
				function()
					require("dap").run_last()
				end,
				desc = "Run Last",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
				end,
				desc = "Terminate",
			},
			{
				"<leader>dK",
				function()
					require("dap.ui.widgets").hover()
				end,
				desc = "Widgets",
			},
		},
		config = function()
			local dap = require("dap")
			-- Go
			-- Requires:
			-- * You have initialized your module with 'go mod init module_name'.
			-- * You :cd your project before running DAP.
			dap.adapters.delve = {
				type = "server",
				port = "${port}",
				executable = {
					command = vim.fn.stdpath("data") .. "/mason/packages/delve/dlv",
					args = { "dap", "-l", "127.0.0.1:${port}" },
				},
			}
			dap.configurations.go = {
				{
					type = "delve",
					name = "Compile module and debug this file",
					request = "launch",
					program = "./${relativeFileDirname}",
				},
				{
					type = "delve",
					name = "Compile module and debug this file (test)",
					request = "launch",
					mode = "test",
					program = "./${relativeFileDirname}",
				},
			}
		end,
		dependencies = {
			{
				"rcarriga/nvim-dap-ui",
				dependencies = "nvim-neotest/nvim-nio",
				keys = {
					{
						"<leader>du",
						function()
							require("dapui").toggle({})
						end,
						desc = "Dap UI",
					},
					{
						"<leader>dE",
						function()
							require("dapui").eval()
						end,
						desc = "Eval",
						mode = { "n", "v" },
					},
				},
				config = function(_, opts)
					local dap, dapui = require("dap"), require("dapui")
					dapui.setup(opts)
					dap.listeners.after.event_initialized["dapui_config"] = function()
						dapui.open({})
					end
					dap.listeners.before.event_terminated["dapui_config"] = function()
						dapui.close({})
					end
					dap.listeners.before.event_exited["dapui_config"] = function()
						dapui.close({})
					end

					local dap_breakpoint = {
						error = {
							text = "🟥",
							texthl = "LspDiagnosticsSignError",
							linehl = "",
							numhl = "",
						},
						rejected = {
							text = "",
							texthl = "LspDiagnosticsSignHint",
							linehl = "",
							numhl = "",
						},
						stopped = {
							text = "⭐️",
							texthl = "LspDiagnosticsSignInformation",
							linehl = "DiagnosticUnderlineInfo",
							numhl = "LspDiagnosticsSignInformation",
						},
					}

					vim.fn.sign_define("DapBreakpoint", dap_breakpoint.error)
					vim.fn.sign_define("DapStopped", dap_breakpoint.stopped)
					vim.fn.sign_define("DapBreakpointRejected", dap_breakpoint.rejected)
				end,
			},
		},
	},

	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {
			modes = {
				char = {
					jump_labels = true,
				},
				search = {
					enabled = false,
				},
			},
		},
	},

	{
		"williamboman/mason.nvim",
		lazy = false,
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			module = "mason",
		},
		config = function()
			require("mason").setup()
			local registry = require("mason-registry")
			local function install_ensured()
				for _, tool in ipairs(tools) do
					local p = registry.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end
			if registry.refresh then
				registry.refresh(install_ensured)
			else
				install_ensured()
			end
			require("mason-lspconfig").setup({ ensure_installed = lsp_servers })
		end,
	},

	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				markdown = { "markdownlint" },
				go = { "golangcilint" },
				rust = { "clippy" },
				python = { "ruff" },
			}
			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
	},

	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			theme = "gruvbox-material",
		},
		config = function(_, opts)
			require("lualine").setup({
				options = opts,
				extensions = { "neo-tree", "lazy" },
			})
		end,
	},

	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				-- See the configuration section for more details
				-- Load luvit types when the `vim.uv` word is found
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		},
	},

	{ "Bilal2453/luvit-meta", lazy = true },

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"nvim-lualine/lualine.nvim",
		},
		opts = {
			current_line_blame = true,
		},
	},

	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			---@diagnostic disable-next-line: missing-fields
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"bash",
					"cmake",
					"css",
					"dockerfile",
					"go",
					"html",
					"java",
					"javascript",
					"json",
					"jsonc",
					"lua",
					"markdown",
					"markdown_inline",
					"python",
					"regex",
					"toml",
					"vim",
					"yaml",
					"rust",
				},
				highlight = {
					enable = true,
				},
				endwise = {
					enable = true,
				},
				indent = { enable = true },
				autopairs = { enable = true },
			})
		end,
	},

	{
		"akinsho/toggleterm.nvim",
		version = "*",
		opts = {
			open_mapping = [[<C-t>]],
			terminal_mappings = true,
			start_in_insert = true,
		},
		config = function(_, opts)
			require("toggleterm").setup({
				options = opts,
			})
		end,
	},

	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
		},
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				mapping = {
					["<C-y>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.confirm({
								select = true,
							})
						else
							fallback()
						end
					end),

					["<C-n>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						else
							fallback()
						end
					end, { "i", "s" }),

					["<C-p>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						else
							fallback()
						end
					end, { "i", "s" }),
				},

				sources = {
					{ name = "nvim_lsp" },
					{ name = "buffer" },
					{
						name = "lazydev",
						group_index = 0, -- set group index to 0 to skip loading LuaLS completions
					},
				},
			})
			-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),
				---@diagnostic disable-next-line: missing-fields
				matching = { disallow_symbol_nonprefix_matching = false },
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "j-hui/fidget.nvim", opts = {} },
		},
		config = function()
			local lspconfig = require("lspconfig")
			local util = require("lspconfig/util")

			local path = util.path

			local function get_python_path(workspace)
				-- Use activated virtualenv.
				if vim.env.VIRTUAL_ENV then
					return path.join(vim.env.VIRTUAL_ENV, "bin", "python")
				end

				-- Find and use virtualenv in workspace directory.
				for _, pattern in ipairs({ "*", ".*" }) do
					local match = vim.fn.glob(path.join(workspace, pattern, "pyvenv.cfg"))
					if match ~= "" then
						return path.join(path.dirname(match), "bin", "python")
					end
				end

				-- Fallback to system Python.
				return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
			end

			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}
			for _, lsp in ipairs(lsp_servers) do
				lspconfig[lsp].setup({
					before_init = function(_, config)
						if lsp == "pyright" then
							config.settings.python.pythonPath = get_python_path(config.root_dir)
						end
					end,
					capabilities = capabilities,
				})
			end
		end,
	},

	{
		"ibhagwan/fzf-lua",
		-- optional for icon support
		dependencies = { "nvim-tree/nvim-web-devicons" },
		init = function()
			vim.api.nvim_create_user_command("Rg", function(opts)
				require("fzf-lua").live_grep({ search = opts.args })
			end, {
				nargs = "?",
				desc = "Grep for text in files.",
			})
		end,
		config = function()
			-- calling `setup` is optional for customization
			require("fzf-lua").setup({})
		end,
	},

	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = "cd app && yarn install",
	},

	{
		"kevinhwang91/nvim-ufo",
		dependencies = {
			"kevinhwang91/promise-async",
			{
				"luukvbaal/statuscol.nvim",
				config = function()
					local builtin = require("statuscol.builtin")
					require("statuscol").setup({
						relculright = true,
						segments = {
							{ text = { builtin.foldfunc }, click = "v:lua.ScFa" },
							{ text = { "%s" }, click = "v:lua.ScSa" },
							{ text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
						},
					})
				end,
			},
		},
		opts = {
			provider_selector = function(_, _, _)
				return { "treesitter", "indent" }
			end,
			fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
				local newVirtText = {}
				local suffix = (" 󰁂 %d "):format(endLnum - lnum)
				local sufWidth = vim.fn.strdisplaywidth(suffix)
				local targetWidth = width - sufWidth
				local curWidth = 0
				for _, chunk in ipairs(virtText) do
					local chunkText = chunk[1]
					local chunkWidth = vim.fn.strdisplaywidth(chunkText)
					if targetWidth > curWidth + chunkWidth then
						table.insert(newVirtText, chunk)
					else
						chunkText = truncate(chunkText, targetWidth - curWidth)
						local hlGroup = chunk[2]
						table.insert(newVirtText, { chunkText, hlGroup })
						chunkWidth = vim.fn.strdisplaywidth(chunkText)
						-- str width returned from truncate() may less than 2nd argument, need padding
						if curWidth + chunkWidth < targetWidth then
							suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
						end
						break
					end
					curWidth = curWidth + chunkWidth
				end
				table.insert(newVirtText, { suffix, "MoreMsg" })
				return newVirtText
			end,
		},
		init = function()
			vim.o.foldcolumn = "1" -- '0' is not bad
			vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
			vim.o.foldlevelstart = 99
			vim.o.foldenable = true
			vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

			vim.keymap.set("n", "zR", require("ufo").openAllFolds)
			vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
		end,
	},

	{
		"kdheepak/lazygit.nvim",
		lazy = false,
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		-- optional for floating window border decoration
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
			-- + brew install jesseduffield/lazygit/lazygit
		},
		keys = {
			{ "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
		},
		config = function()
			require("telescope").load_extension("lazygit")
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"debugloop/telescope-undo.nvim",
		},
		init = function()
			local undodir = vim.fn.stdpath("data") .. "/undodir"
			local handle = io.open(undodir)
			if handle then
				handle:close()
			else
				os.execute("mkdir -p " .. undodir)
			end
			vim.opt.undodir = undodir
			vim.opt.undofile = true
		end,
		config = function()
			require("telescope").setup({})
			require("telescope").load_extension("undo")
			-- optional: vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>")
		end,
	},
}
