vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 3
vim.o.shiftwidth = 3
vim.g.mapleader = " "
vim.o.wrap = false -- do not break lines to fit in screen
vim.o.scrolloff = 5
vim.o.undofile = true --guardar undo entre saves

vim.pack.add ({
		{ src="https://github.com/nvim-lua/plenary.nvim"},
		{ src="https://github.com/nvim-telescope/telescope.nvim"},
		{ src="https://github.com/goolord/alpha-nvim" },
		{ src = "https://github.com/hrsh7th/nvim-cmp" },
		{ src="https://github.com/catppuccin/nvim", as = "catppuccin" },
		{ src = "https://github.com/hrsh7th/cmp-nvim-lsp" },
		{ src = "https://github.com/hrsh7th/cmp-buffer" },
		{ src = "https://github.com/barrettruth/live-server.nvim" },
})

dofile(vim.fn.stdpath("config") .. "/alpha.lua")
vim.cmd("colorscheme catppuccin")
local tg = { "Normal","NormalNC","LineNr","NonText", "VertSplit", "StatusLine", "StatusLineNC", "TelescopeNormal","TelescopeBorder", "TelescopePromptNormal","TelescopePromptBorder", "TelescopePreviewNormal", "TelescopePreviewBorder", "TelescopeResultsNormal", "TelescopeResultsBorder"}
for _, x in ipairs(tg) do
  vim.api.nvim_set_hl(0, x, { bg = "none" })
end

local keymaps = {
		{{'n','v','x'}, '<leader>y', '"+y'}, -- copiar al portapapeles del sistema
		{{'n','v','x'}, '<leader>d', '"+d'}, -- cortar del portapapeles del sistema
		{{'n'}, '<Tab>', ':bnext<CR>'}, -- cambiar a la siguiente pestaña
		{{'n'}, '<S-Tab>', ':bprevious<CR>'}, -- cambiar a la pestaña anterior anterior
		{{'n'}, '<leader>w', ':write<CR>'}, -- guardar archivo
		{{'n'}, '<leader>f', ':Telescope find_files<CR>'}, -- buscar archivos
		{{'n'}, '<leader>g', ':Telescope live_grep<CR>'}, -- buscar en archivos
		{{'n'}, '<leader>h', ':Telescope help_tags<CR>'}, -- buscar en la ayuda
		{{'n'}, '<leader>b', ':Telescope buffers<CR>'}, -- listar buffers
		{{'n'}, '<leader>r', ':Telescope oldfiles<CR>'}, -- listar recent
	   {{'v'}, 'J', ":m '>+1<CR>gv=gv"}, --mv lines
		{{'v'}, 'K', ":m '<-2<CR>gv=gv"},
		{{'n'}, 'n', 'nzzzv'}, --better next in lists
		{{'n'}, 'N', 'nzzzv'},
		{{'n'}, '<leader>l', ':LiveServerToggle<CR>'}, -- live preview
}

for _, k in ipairs(keymaps) do
	vim.keymap.set(k[1], k[2], k[3])
end

--C/C++ full setup
vim.o.completeopt = "menu,menuone,noselect"
local cmp = require("cmp")
vim.lsp.config("clangd", {
    filetypes = { "c", "cpp" },
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
    cmd = {
        "clangd",
        "--query-driver=/opt/st/**/bin/*,/opt/OSELAS.Toolchain*/**/bin/*",
        "--header-insertion=never",
    },
})


vim.lsp.enable("clangd")

--Web (HTML/CSS/JS) setup
vim.lsp.enable({ "ts_ls", "html", "cssls", "jsonls" })
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local o = { buffer = ev.buf }

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, o)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, o)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, o)
    end,
})

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
})

cmp.setup({
    mapping = {
        ["<Tab>"] = cmp.mapping.select_next_item(),
        ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
    },
    sources = {
        { name = "nvim_lsp" },
        { name = "buffer" },
    },
})
