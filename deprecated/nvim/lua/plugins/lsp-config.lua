return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end
	},

	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "lua_ls", "html", "bashls", "ast_grep", "pyright" } --meter el nombre del LSP que encuentras en :Mason aqui para snippets
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local lspconfig = require("lspconfig")
			lspconfig.lua_ls.setup({
				capabilities = capabilities
			})
			lspconfig.html.setup({
				capabilities = capabilities
			})
			lspconfig.bashls.setup({
				capabilities = capabilities,
				filetypes = { "sh", "bashls" },
			})
			lspconfig.ast_grep.setup({ -- Añadir el servidor aqui metiendo las capabilities
				capabilities = capabilities
			})
			lspconfig.pyright.setup({
				capabilities = capabilities
			})


			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition, { desc = "[C]ode [D]efinition" })
			vim.keymap.set("n", "<leader>cr", vim.lsp.buf.references, { desc = "[C]ode [R]eferences" })
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "[C]ode [Actions]" })
		end,
	},
}
