
return {
  "yetone/avante.nvim",
  -- Avante depende de estos plugins; algunos son opcionales pero recomendados
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- Iconos para la interfaz
    "stevearc/dressing.nvim",      -- Mejoras en los menús de entrada
    "nvim-lua/plenary.nvim",       -- Utilidades de Lua para Neovim
    "MunifTanjim/nui.nvim",        -- Librería de interfaces para Neovim
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = { file_types = { "markdown", "Avante" } },
      ft = { "markdown", "Avante" },
    },
  },
  -- Avante requiere compilar un binario (si tu entorno lo permite)
  build = "make",

  -- Opciones de configuración de Avante
  opts = {
    -- Si quieres usar GitHub Copilot como backend para sugerencias
    provider = "copilot",

    -- Opciones para personalizar la ventana lateral
    windows = {
      sidebar_header = {
        enabled = false,
      },
    },

    -- Si quisieras usar OpenAI en lugar de Copilot:
    -- provider = "openai",
    -- openai_api_key = "TU_API_KEY",
  },
}

--return {
--  "yetone/avante.nvim",
--  dependencies = {
--    "nvim-tree/nvim-web-devicons",
--    "stevearc/dressing.nvim",
--    "nvim-lua/plenary.nvim",
--    "MunifTanjim/nui.nvim",
--    {
--      "MeanderingProgrammer/render-markdown.nvim",
--      opts = { file_types = { "markdown", "Avante" } },
--      ft = { "markdown", "Avante" },
--    },
--  },
--  build = "make",
--  opts = { provider = "copilot",
--	windows = {
--			sidebar_header = {
--				enabled = false
--			}
--		}
--
--  },
--}
