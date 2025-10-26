vim.g.mapleader = " "
vim.opt.showmode = false --disable mouse pos
vim.g.have_nerd_font = true --enable nerdfont
vim.opt.number = true --enable fix count
vim.opt.mouse = "a" -- enable mouse
vim.opt.cursorline = false --disable cursor pos
vim.opt.relativenumber = true --enable relative number
vim.opt.scrolloff = 10 --min num of lines to show when scorlling onwards
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>") --clean buffer for when searching with /
vim.opt.clipboard = "unnamedplus" -- Usa el portapapeles del sistema

--  Use CTRL+<hjkl> to switch between windows
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

--highlight when yanking
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

ui = {
		-- If you are using a Nerd Font: set icons to an empty table which will use the
		-- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
		icons = vim.g.have_nerd_font and {} or {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	}

-- Función para ejecutar el archivo según su extensión
local function run_file()
  -- Obtener el nombre del archivo actual
  local file = vim.fn.expand('%')
  local ext = vim.fn.expand('%:e') -- Obtiene la extensión del archivo

  -- Tabla de comandos según la extensión
  local commands = {
    py = 'python3 %',
    js = 'node %',
    ts = 'ts-node %',
    sh = 'bash %',
    lua = 'lua %',
    c = 'gcc % -o %:r && ./%:r',
    cpp = 'g++ % -o %:r && ./%:r',
    java = 'javac % && java %:r',
    go = 'go run %',
    rs = 'cargo run %',
    rb = 'ruby %',
    php = 'php %'
  }

  -- Obtener el comando correspondiente a la extensión
  local cmd = commands[ext]

  if cmd then
    vim.cmd('wa')
    -- Reemplazar % con el nombre del archivo en el comando
    cmd = cmd:gsub('%%', file)
    -- Ejecutar el comando usando :!
    vim.cmd('!' .. cmd)
  else
    print('No hay un comando configurado para .' .. ext)
  end
end

-- Asignar la función a <leader>r
vim.keymap.set('n', '<leader>r', run_file, { noremap = true, silent = true })

