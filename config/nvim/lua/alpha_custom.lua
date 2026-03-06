return {
    'goolord/alpha-nvim',
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

        -- Funciones internas de alpha
        local function getLen(str, start_pos)
            local byte = string.byte(str, start_pos)
            if not byte then return nil end
            return (byte < 0x80 and 1) or (byte < 0xE0 and 2) or (byte < 0xF0 and 3) or (byte < 0xF8 and 4) or 1
        end

        local function colorize(header, header_color_map, colors)
            for letter, color in pairs(colors) do
                local color_name = "Alpha_" .. letter
                vim.api.nvim_set_hl(0, color_name, {fg = color})
                colors[letter] = color_name
            end

            local colorized = {}
            for i, line in ipairs(header_color_map) do
                local colorized_line = {}
                local pos = 0
                for j = 1, #line do
                    local start = pos
                    pos = pos + getLen(header[i], start + 1)
                    local color_name = colors[line:sub(j,j)]
                    if color_name then
                        table.insert(colorized_line, { color_name, start, pos })
                    end
                end
                table.insert(colorized, colorized_line)
            end
            return colorized
        end

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

		  local colors = {
            ["A"] = "#f5e0dd",
            ["B"] = "#edbe75",
            ["C"] = "#181826",
            ["D"] = "#FF0000",
            ["E"] = "#7c5632",
            ["F"] = "#a28250",
            ["G"] = "#bb965d",
            ["H"] = "#482926",
            ["I"] = "#38291B",
            ["J"] = "#00FF00",
            ["K"] = "#502E2B",
            ["L"] = "#0000FF",
            ["M"] = "#FFFFFF",
            ["N"] = "#FFFFFF",
            ["O"] = "#896e44",
            ["P"] = "#FFFFFF",
            ["Q"] = "#986a3e",
            ["R"] = "#BF854E",
            ["S"] = "#bac2df",
            ["T"] = "#FFFFFF",
            ["U"] = "#bb965d",
            ["V"] = "#FFFFFF",
            ["W"] = "#FFFFFF",
            ["Y"] = "#FAC87C",
            ["X"] = "#c8a063",
            ["Z"] = "#11111c",
			}

		  -- Crear header de bloques
        local header = {}
        for _, line in ipairs(color_map) do
            local header_line = ""
            for i = 1, #line do
                header_line = header_line .. (line:sub(i,i) ~= " " and "█" or " ")
            end
            table.insert(header, header_line)
        end


        -- Aplicar colores
        local colorized = colorize(header, color_map, colors)

        dashboard.section.header.val = header
        dashboard.section.header.opts = {
            hl = colorized,
            position = "center",
        }

        -- Botones del dashboard
        dashboard.section.buttons.val = {
            dashboard.button("n", "  > New file", ":ene <BAR> startinsert <CR>"),
            dashboard.button("f", "󰈞  > Find file", ":cd $HOME | Telescope find_files<CR>"),
            dashboard.button("r", "  > Recent", ":Telescope oldfiles<CR>"),
            dashboard.button("s", "  > Settings", ":e $MYVIMRC | :cd %:p:h <CR>"),
            dashboard.button("q", "󰩈  > Quit", ":qa<CR>"),
        }

        -- Activar alpha
        alpha.setup(dashboard.opts)

        -- Deshabilitar folding en buffer de alpha
        vim.cmd("autocmd FileType alpha setlocal nofoldenable")
    end
}
