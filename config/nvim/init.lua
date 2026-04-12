vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 3
vim.o.shiftwidth = 3
vim.g.mapleader = " "
vim.o.wrap = false -- do not break lines to fit in screen
vim.o.scrolloff = 5

vim.pack.add ({
		{ src="https://github.com/nvim-lua/plenary.nvim"},
		{ src="https://github.com/nvim-telescope/telescope.nvim"},
		{ src="https://github.com/goolord/alpha-nvim" },
		{ src="https://github.com/catppuccin/nvim", as = "catppuccin" },
		{ src="https://github.com/neovim/nvim-lspconfig" },
		{ src="https://github.com/hrsh7th/nvim-cmp" },
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
		{{'v'}, 'J', ":m '>+1<CR>gv=gv"},
		{{'v'}, 'K', ":m '<-2<CR>gv=gv"},
		{{'n'}, 'n', 'nzzzv'},
		{{'n'}, 'N', 'nzzzv'},
}

for _, k in ipairs(keymaps) do
	vim.keymap.set(k[1], k[2], k[3])
end

-- C/C++
-- Opciones de completado
vim.o.completeopt = "menuone,noselect"

-- Función para crear keymaps LSP en el buffer
local function lsp_keymaps(bufnr)
    local opts = { noremap=true, silent=true, buffer=bufnr }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
end

-- Configuración del cliente LSP
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp" },
    callback = function()
        local clients = vim.lsp.get_clients({ name = "clangd" })
        if #clients == 0 then
            vim.lsp.start({
                name = "clangd",
                cmd = { "clangd", "--background-index" },
                filetypes = { "c", "cpp" },
                root_dir = vim.loop.cwd(),
            })
        end

        -- Asigna keymaps LSP para este buffer
        lsp_keymaps(0)
    end
})

-- Diagnósticos visibles
vim.diagnostic.config({
    virtual_text = true,  -- muestra errores como texto en la línea
    signs = true,         -- muestra signos en la columna
    underline = true,     -- subraya los errores
    update_in_insert = true, -- actualiza en modo insert
})
local cmp = require('cmp')

cmp.setup({
    mapping = {
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
    },
    sources = {
        { name = 'nvim_lsp' },
        { name = 'buffer' },
    }
})
