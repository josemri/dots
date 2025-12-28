vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = false
vim.o.tabstop = 4
vim.o.swapfile = false
vim.g.mapleader = " "
vim.o.winborder="rounded"

vim.pack.add({
	{src = "https://github.com/vague2k/vague.nvim"},
    {src = "https://github.com/kyazdani42/nvim-tree.lua" },
	{src = "https://github.com/chomosuke/typst-preview.nvim"},
	{src = "https://github.com/github/copilot.vim"},
	{src = "https://github.com/akinsho/toggleterm.nvim"},
	{src = "https://github.com/akinsho/bufferline.nvim"},
    {src = "https://github.com/nvim-lua/plenary.nvim"},
	{src = "https://github.com/nvim-telescope/telescope.nvim"},
})

require "nvim-tree".setup()
require "toggleterm".setup()
require "bufferline".setup(
  {
    options = {
	  always_show_bufferline = false,
    }
  }
)

vim.cmd("colorscheme vague")
vim.cmd(":hi statusline guibg=NONE")

local keymaps = {
		{{'n'}, '<leader>o', ':update<CR> :source<CR>'}, -- guardar y recargar el init.lua
		{{'n'}, '<leader>w', ':write<CR>'}, -- guardar archivo
		{{'n'}, '<leader>q', ':quit<CR>'}, -- salir de neovim
		{{'n','v','x'}, '<leader>y', '"+y<CR>'}, -- copiar al portapapeles del sistema
		{{'n','v','x'}, '<leader>d', '"+d<CR>'}, -- cortar del portapapeles del sistema
        {{'n'}, '<leader>e', ':NvimTreeToggle<CR>'}, -- abrir el explorador de archivos
		{{'n'}, '<leader>t', ':ToggleTerm size=15 direction=horizontal<CR>'}, -- abrir terminal
		{{'n'}, '<leader>a', function() --abrir terminal y explorador de archivos
		  vim.cmd('ToggleTerm size=15 direction=horizontal')
		  vim.cmd('NvimTreeToggle')
		end},
		{{'n'}, '<Tab>', ':BufferLineCycleNext<CR>'}, -- cambiar a la siguiente pestaña
		{{'n'}, '<S-Tab>', ':BufferLineCyclePrev<CR>'}, -- cambiar a la pestaña anterior
		{{'n'}, '<leader>f', ':Telescope find_files<CR>'}, -- buscar archivos
		{{'n',}, '<leader>g', ':Telescope live_grep<CR>'}, -- buscar en archivos
		{{'n',}, '<leader>h', ':Telescope help_tags<CR>'}, -- buscar en la ayuda
}

for _, k in ipairs(keymaps) do
	vim.keymap.set(k[1], k[2], k[3])
end
