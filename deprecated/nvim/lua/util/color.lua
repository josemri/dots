local M = {}

-- Definimos algunos colores por nombre
local colors = {
    yellow = {r = 255, g = 255, b = 0},
    red = {r = 255, g = 0, b = 0},
    green = {r = 0, g = 255, b = 0},
    -- Agrega más colores si es necesario
}

-- Función para convertir un color hexadecimal a RGB
local function hex_to_rgb(hex)
    local r, g, b = hex:match("#(..)(..)(..)")
    return {
        r = tonumber(r, 16),
        g = tonumber(g, 16),
        b = tonumber(b, 16)
    }
end

-- Función para oscurecer un color
function M.darken(color_input, factor)
    local color

    -- Verificar si el input es un nombre de color o un valor hexadecimal
    if colors[color_input] then
        color = colors[color_input]
    else
        -- Si es hexadecimal, lo convertimos a RGB
        color = hex_to_rgb(color_input)
    end

    -- Limita el factor de oscurecimiento entre 0 y 100
    factor = math.max(0, math.min(factor, 100))

    -- Aplicar el oscurecimiento a cada componente del color
    local function darken_component(c)
        return math.floor(c * (1 - factor / 100))
    end

    local darkened_color = {
        r = darken_component(color.r),
        g = darken_component(color.g),
        b = darken_component(color.b)
    }

    -- Devuelve el color oscurecido en formato RGB
    return string.format("#%02X%02X%02X", darkened_color.r, darkened_color.g, darkened_color.b)
end

return M

