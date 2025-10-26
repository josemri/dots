return {
    "mfussenegger/nvim-dap", -- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
    },
    config = function()
        local dap, dapui = require("dap"), require("dapui")
        dap.listeners.before.attach.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
            dapui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
            dapui.close()
        end
        vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "[D]ebugger [B]reakpoint" })
        vim.keymap.set("n", "<leader>ds", dap.continue, { desc = "[D]ebugger [S]tart" })

        dapui.setup({
            layouts = {
                {
                    elements = {
                        { id = "scopes", size = 0.25 },
                        { id = "breakpoints", size = 0.25 },
                        { id = "stacks", size = 0.25 },
                        { id = "watches", size = 0.25 },
                    },
                    size = 40,
                    position = "left",
                },
                {
                    elements = {
                        { id = "repl", size = 0.5 },
                        { id = "console", size = 0.5 },
                    },
                    size = 10,
                    position = "bottom",
                },
            },
        })

        -- Bash Debugger
        dap.adapters.bashdb = {
            type = "executable",
            command = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/bash-debug-adapter",
            name = "bashdb",
        }

        dap.configurations.sh = {
            {
                type = "bashdb",
                request = "launch",
                name = "Launch file",
                showDebugOutput = true,
                pathBashdb = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir/bashdb",
                pathBashdbLib = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir",
                trace = true,
                file = "${file}",
                program = "${file}",
                cwd = "${workspaceFolder}",
                pathCat = "cat",
                pathBash = "/bin/bash",
                pathMkfifo = "mkfifo",
                pathPkill = "pkill",
                args = {},
                env = {},
                terminalKind = "integrated",
            },
        }

        -- Python Debugger
        dap.adapters.python = {
            type = "executable",
            command = "/usr/bin/python3", -- Ajusta esto según tu entorno
            args = { "-m", "debugpy.adapter" },
        }

        dap.configurations.python = {
            {
                type = "python",
                request = "launch",
                name = "Launch file",
                program = "${file}",
                pythonPath = function()
                    return "/usr/bin/python3"
                end,
            },
            {
                type = "python",
                request = "attach",
                name = "Attach to process",
                connect = {
                    host = "127.0.0.1",
                    port = 5678,
                },
                pythonPath = function()
                    return "/usr/bin/python3"
                end,
            },
        }
    end,
}

