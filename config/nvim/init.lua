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
		{ src="https://github.com/nvim-telescope/telescope.nvim"}, --telescope y dependencia
		{ src="https://github.com/goolord/alpha-nvim" },
		{ src="https://github.com/catppuccin/nvim", as = "catppuccin" },
		{ src = "https://github.com/barrettruth/live-server.nvim" }, -- html preview
		{ src = "https://github.com/twhlynch/notebook.nvim" }, -- jupyter notebook support
		{ src = "https://github.com/3rd/image.nvim" }, -- image rendering
		{ src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" }, -- markdown formatting
})

dofile(vim.fn.stdpath("config") .. "/alpha.lua")
require("catppuccin").setup({ transparent_background = true })
vim.cmd("colorscheme catppuccin")

local keymaps = {
		{{'n','v','x'}, '<leader>y', '"+y'}, -- copiar al portapapeles del sistema
		{{'n','v','x'}, '<leader>d', '"+d'}, -- cortar del portapapeles del sistema
		{{'n'}, '<Tab>', ':bnext<CR>'}, -- siguiente pestaña
		{{'n'}, '<leader>w', ':write<CR>'}, -- guardar archivo
		{{'n'}, '<leader>f', ':Telescope find_files<CR>'}, -- buscar archivos
		{{'n'}, '<leader>g', ':Telescope live_grep<CR>'}, -- buscar en archivos
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

require("image").setup()
require("notebook").setup()
