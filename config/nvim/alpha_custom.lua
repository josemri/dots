return {
    'goolord/alpha-nvim',
    dependencies = { 'echasnovski/mini.icons' },
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

        -- Función interna para oscurecer colores hexadecimales
        local function darken(hex, factor)
            factor = math.max(0, math.min(factor, 100))
            local r, g, b = hex:match("#(..)(..)(..)")
            r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
            r = math.floor(r * (1 - factor / 100))
            g = math.floor(g * (1 - factor / 100))
            b = math.floor(b * (1 - factor / 100))
            return string.format("#%02X%02X%02X", r, g, b)
        end

        -- Funciones internas de alpha
        local function getLen(str, start_pos)
            local byte = string.byte(str, start_pos)
            if not byte then return nil end
            return (byte < 0x80 and 1) or (byte < 0xE0 and 2) or (byte < 0xF0 and 3) or (byte < 0xF8 and 4) or 1
        end

        local function colorize(header, header_color_map, colors)
            for letter, color in pairs(colors) do
                local color_name = "Alpha_" .. letter
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
                    local color_name = colors[line:sub(j,j)]
                    if color_name then
                        table.insert(colorized_line, { color_name, start, pos })
                    end
                end
                table.insert(colorized, colorized_line)
            end
            return colorized
        end

        -- Paleta de colores y mapa de letras
        local mocha = require("catppuccin.palettes").get_palette("mocha")

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
            ["A"] = { fg = mocha.rosewater},
            ["B"] = { fg = darken("#FAC87C",5) },
            ["C"] = { fg = mocha.mantle },
            ["D"] = { fg = "#FF0000" },
            ["E"] = { fg = darken("#BF854E", 35)},
            ["F"] = { fg = darken("#FAC87C", 35) },
            ["G"] = { fg = darken("#FAC87C", 25) },
            ["H"] = { fg = darken("#502E2B", 10) },
            ["I"] = { fg = "#38291B" },
            ["J"] = { fg = "#00FF00" },
            ["K"] = { fg = "#502E2B" },
            ["L"] = { fg = "#0000FF" },
            ["M"] = { fg = "#FFFFFF" },
            ["N"] = { fg = "#FFFFFF" },
            ["O"] = { fg = darken("#FAC87C", 45) },
            ["P"] = { fg = "#FFFFFF" },
            ["Q"] = { fg = darken("#BF854E", 20) },
            ["R"] = { fg = "#BF854E" },
            ["S"] = { fg = mocha.subtext1},
            ["T"] = { fg = "#FFFFFF" },
            ["U"] = { fg = darken("#FAC87C", 25) },
            ["V"] = { fg = "#FFFFFF" },
            ["W"] = { fg = "#FFFFFF" },
            ["Y"] = { fg = "#FAC87C" },
            ["X"] = { fg = darken("#FAC87C",20) },
            ["Z"] = { fg = mocha.crust },
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

        -- Agregar un título extra
        -- table.insert(header, "                      vim                      ")

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
            dashboard.button("s", "  > Settings", ":e $MYVIMRC | :cd %:p:h | :Neotree filesystem toggle left<CR>"),
            dashboard.button("q", "󰩈  > Quit", ":qa<CR>"),
        }

        -- Activar alpha
        alpha.setup(dashboard.opts)

        -- Deshabilitar folding en buffer de alpha
        vim.cmd("autocmd FileType alpha setlocal nofoldenable")
    end
}





