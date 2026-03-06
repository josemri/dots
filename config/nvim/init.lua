vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 3
vim.o.shiftwidth = 3
vim.g.mapleader = " "
vim.o.wrap = false -- do not break lines to fit in screen
vim.o.scrolloff = 5 -- 5 lines margin

vim.pack.add ({
		{ src="https://github.com/nvim-lua/plenary.nvim"},
		{ src="https://github.com/nvim-telescope/telescope.nvim"},
		{ src="https://github.com/goolord/alpha-nvim" },
		{ src="https://github.com/catppuccin/nvim", as = "catppuccin" },
})

dofile(vim.fn.stdpath("config") .. "/alpha.lua")
vim.cmd("colorscheme catppuccin")

-- transparency
local tg = { "Normal","NormalNC","LineNr","NonText", "VertSplit", "StatusLine", "StatusLineNC", "TelescopeNormal","TelescopeBorder", "TelescopePromptNormal","TelescopePromptBorder", "TelescopePreviewNormal", "TelescopePreviewBorder", "TelescopeResultsNormal", "TelescopeResultsBorder"}
for _, x in ipairs(tg) do
  vim.cmd(string.format("hi %s guibg=NONE ctermbg=NONE", x))
end
-- transparency

local keymaps = {
		{{'n'}, '<leader>o', ':update<CR> :source<CR>'}, -- guardar y recargar el init.lua
		{{'n'}, '<leader>w', ':write<CR>'}, -- guardar archivo
		{{'n'}, '<leader>q', ':quit<CR>'}, -- salir de neovim
		{{'n','v','x'}, '<leader>y', '"+y<CR>'}, -- copiar al portapapeles del sistema
		{{'n','v','x'}, '<leader>d', '"+d<CR>'}, -- cortar del portapapeles del sistema
		{{'n'}, '<Tab>', ':bnext<CR>'}, -- cambiar a la siguiente pestaña
		{{'n'}, '<S-Tab>', ':bprevious<CR>'}, -- cambiar a la siguiente pestaña
		{{'n'}, '<leader>f', ':Telescope find_files<CR>'}, -- buscar archivos
		{{'n'}, '<leader>g', ':Telescope live_grep<CR>'}, -- buscar en archivos
		{{'n'}, '<leader>h', ':Telescope help_tags<CR>'}, -- buscar en la ayuda
		{{'n'}, '<leader>b', ':Telescope buffers<CR>'}, -- listar buffers
}

for _, k in ipairs(keymaps) do
	vim.keymap.set(k[1], k[2], k[3])
end
