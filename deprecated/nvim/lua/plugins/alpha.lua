return {
	'goolord/alpha-nvim',
	dependencies = { 'echasnovski/mini.icons' },
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")

local function getLen(str, start_pos)
	local byte = string.byte(str, start_pos)
	if not byte then
		return nil
	end
	return (byte < 0x80 and 1) or (byte < 0xE0 and 2) or (byte < 0xF0 and 3) or (byte < 0xF8 and 4) or 1
end

local function colorize(header, header_color_map, colors)
	for letter, color in pairs(colors) do
		local color_name = "AlphaJemuelKwelKwelWalangTatay" .. letter
		vim.api.nvim_set_hl(0, color_name, color)
		colors[letter] = color_name
	end

	local colorized = {}

	for i, line in ipairs(header_color_map) do
		local colorized_line = {}
		local pos = 0

		for j = 1, #line do
			local start = pos
			pos = pos + getLen(header[i], start + 1)

			local color_name = colors[line:sub(j, j)]
			if color_name then
				table.insert(colorized_line, { color_name, start, pos })
			end
		end

		table.insert(colorized, colorized_line)
	end

	return colorized
end

	local color = require("util.color")
	local mocha = require("catppuccin.palettes").get_palette("mocha")
	local dashboard = require("alpha.themes.dashboard")
		local color_map = {
		[[      AAAA]],
		[[AAAAAA  AAAA]],
		[[AA    AAAA  AAAA        KKHHKKHHHH]],
		[[AAAA    AAAA  AA    HHBBKKKKKKKKKKKKKK]],
		[[  AAAAAA      AAKKBBHHKKBBYYBBKKKKHHKKKKKK]],
		[[      AAAA  BBAAKKHHBBBBKKKKBBYYBBHHHHKKKKKK]],
		[[        BBAABBKKYYYYHHKKYYYYKKKKBBBBBBZZZZZZ]],
		[[    YYBBYYBBKKYYYYYYYYYYKKKKBBKKAAAAZZOOZZZZ]],
		[[    XXXXYYYYBBYYYYYYYYBBBBBBKKKKBBBBAAAAZZZZ]],
		[[    XXXXUUUUYYYYBBYYYYYYBBKKBBZZOOAAZZOOAAAAAA]],
		[[  ZZZZZZXXUUXXXXYYYYYYYYBBAAAAZZOOOOAAOOZZZZAAAA]],
		[[  ZZUUZZXXUUUUXXXXUUXXFFFFFFFFAAAAOOZZAAZZZZ  AA]],
		[[    RRRRUUUUZZZZZZZZXXOOFFFFOOZZOOAAAAAAZZZZAA]],
		[[    CCSSUUUUZZXXXXZZXXOOFFFFOOZZOOOOZZOOAAAA]],
		[[    CCCCUUUUUUUUUURRRROOFFFFOOZZOOOOZZOOZZZZ]],
		[[    CCCCUUUUUUUUSSCCCCEEQQQQOOZZOOOOZZOOZZZZ]],
		[[    CCCCUUGGUUUUCCCCCCEEQQQQOOZZOOOOZZEEZZ]],
		[[    RRRRGGGGUUGGCCCCCCOOOOOOOOZZOOEEZZII]],
		[[      IIRRGGGGGGCCCCCCOOOOOOOOZZEEII]],
		[[            GGRRCCCCCCOOOOEEEEII  II]],
		[[                RRRRRREEEE  IIII]],
		[[                      II]],
		[[]],
	}

	local white = "#FFFFFF"
	local yellow = "#FAC87C"
	local orange = "#BF854E"
	local maroon = "#502E2B"
	local brown = "#38291B"
	local red = "#FF0000"
	local green = "#00FF00"
	local blue = "#0000FF"
	local colors = {
		["A"] = { fg = mocha.rosewater},
		["B"] = { fg = color.darken(yellow,5) },
		["C"] = { fg = mocha.mantle },
		["D"] = { fg = red },
		["E"] = { fg = color.darken(orange, 35)},
		["F"] = { fg = color.darken(yellow, 35) },
		["G"] = { fg = color.darken(yellow, 25) },
		["H"] = { fg = color.darken(maroon, 10) },
		["I"] = { fg = brown },
		["J"] = { fg = green },
		["K"] = { fg = maroon },
		["L"] = { fg = blue },
		["M"] = { fg = white },
		["N"] = { fg = white },
		["O"] = { fg = color.darken(yellow, 45) },
		["P"] = { fg = white },
		["Q"] = { fg = color.darken(orange, 20) },
		["R"] = { fg = orange },
		["S"] = { fg = mocha.subtext1},
		["T"] = { fg = white },
		["U"] = { fg = color.darken(yellow, 25) },
		["V"] = { fg = white },
		["W"] = { fg = white },
		["Y"] = { fg = yellow },
		["X"] = { fg = color.darken(yellow,20) },
		["Z"] = { fg = mocha.crust },
	}
	local header = {}
	for _, line in ipairs(color_map) do
		local header_line = [[]]
		for i = 1, #line do
			if line:sub(i, i) ~= " " then
				header_line = header_line .. "█"
			else
				header_line = header_line .. " "
			end
		end
		table.insert(header, header_line)
	end

	local header_add = [[          N        E      O    B   E E         ]]
	local header_add = [[                      vim                      ]]
	local header_add = [[                                            ]]
	table.insert(header, header_add)

	local hl_add = {}
	for i = 1, #header_add do
		table.insert(hl_add, {"NeoBeeTitle", 1, i})
	end

	dashboard.section.header.val = header
	local colorized = colorize(header, color_map, colors)

	table.insert(colorized, hl_add)

	dashboard.section.header.opts = {
		hl = colorized,
		position = "center",
	}

		-- Set header
		local header_lines = {
			[[                                                     ]],
			[[  ███▄    █ ▓█████  ▒█████   ██▒   █▓ ██▓ ███▄ ▄███▓ ]],
			[[  ██ ▀█   █ ▓█   ▀ ▒██▒  ██▒▓██░   █▒▓██▒▓██▒▀█▀ ██▒ ]],
			[[ ▓██  ▀█ ██▒▒███   ▒██░  ██▒ ▓██  █▒░▒██▒▓██    ▓██░ ]],
			[[ ▓██▒  ▐▌██▒▒▓█  ▄ ▒██   ██░  ▒██ █░░░██░▒██    ▒██  ]],
			[[ ▒██░   ▓██░░▒████▒░ ████▓▒░   ▒▀█░  ░██░▒██▒   ░██▒ ]],
			[[ ░ ▒░   ▒ ▒ ░░ ▒░ ░░ ▒░▒░▒░    ░ ▐░  ░▓  ░ ▒░   ░  ░ ]],
			[[ ░ ░░   ░ ▒░ ░ ░  ░  ░ ▒ ▒░    ░ ░░   ▒ ░░  ░      ░ ]],
			[[    ░   ░ ░    ░   ░ ░ ░ ▒       ░░   ▒ ░░      ░    ]],
			[[          ░    ░  ░    ░ ░        ░   ░         ░    ]],
			[[                                 ░                   ]],
			[[                                                     ]],
		}

		-- dashboard.section.header.val = header_lines
		-- Set menu
		dashboard.section.buttons.val = {
			dashboard.button( "e", "  > New file" , ":ene <BAR> startinsert <CR>"),
			dashboard.button( "f", "󰈞  > Find file", ":cd $HOME | Telescope find_files<CR>"),
			dashboard.button( "r", "  > Recent"   , ":Telescope oldfiles<CR>"),
			dashboard.button( "s", "  > Settings" , ":e $MYVIMRC | :cd %:p:h | :Neotree filesystem toggle left<CR>"),
			dashboard.button( "q", "󰩈  > Quit NVIM", ":qa<CR>"),
		}

		-- Send config to alpha
		alpha.setup(dashboard.opts)

		-- Disable folding on alpha buffer
		vim.cmd([[
		    autocmd FileType alpha setlocal nofoldenable
		    ]])
	end
}
