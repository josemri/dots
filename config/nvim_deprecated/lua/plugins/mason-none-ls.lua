-- mason-null-ls: integración de Mason con Null-ls
return {
    "jay-babu/mason-null-ls.nvim",
    dependencies = {
        "williamboman/mason.nvim",
        "nvimtools/none-ls.nvim", -- null-ls renombrado
    },
    config = function()
        require("mason").setup()
        require("mason-null-ls").setup({
            ensure_installed = {
                "stylua",     -- Ya instalado en tu sistema
            },
            automatic_installation = true, -- Instala automáticamente las herramientas listadas
        })

        local null_ls = require("null-ls")
        null_ls.setup({
            sources = {
                null_ls.builtins.formatting.stylua,   -- Configuración de stylua
            },
        })
    end,
}

