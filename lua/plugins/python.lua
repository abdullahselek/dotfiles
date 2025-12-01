return {
  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
              },
            },
          },
        },
        ruff_lsp = {
          init_options = {
            settings = {
              -- Use project's pyproject.toml configuration
              args = {},
            },
          },
        },
      },
    },
  },

  -- None-ls for additional formatting and linting
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = opts.sources or {}

      -- Add formatters
      table.insert(
        opts.sources,
        nls.builtins.formatting.black.with({
          extra_args = { "--config", vim.fn.getcwd() .. "/pyproject.toml" },
          condition = function(utils)
            return utils.root_has_file("pyproject.toml")
          end,
        })
      )

      table.insert(
        opts.sources,
        nls.builtins.formatting.isort.with({
          extra_args = { "--settings-path", vim.fn.getcwd() .. "/pyproject.toml" },
          condition = function(utils)
            return utils.root_has_file("pyproject.toml")
          end,
        })
      )

      -- Add mypy for type checking
      table.insert(
        opts.sources,
        nls.builtins.diagnostics.mypy.with({
          extra_args = { "--config-file", vim.fn.getcwd() .. "/pyproject.toml" },
          condition = function(utils)
            return utils.root_has_file("pyproject.toml")
          end,
        })
      )

      -- Add ruff for linting
      table.insert(
        opts.sources,
        nls.builtins.diagnostics.ruff.with({
          condition = function(utils)
            return utils.root_has_file("pyproject.toml")
          end,
        })
      )
    end,
  },

  -- Conform for formatting (alternative/complement to none-ls)
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        python = { "isort", "black" },
      },
      formatters = {
        black = {
          prepend_args = { "--config", vim.fn.getcwd() .. "/pyproject.toml" },
        },
        isort = {
          prepend_args = { "--settings-path", vim.fn.getcwd() .. "/pyproject.toml" },
        },
      },
    },
  },

  -- nvim-lint for linting (alternative/complement to none-ls)
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        python = { "mypy", "ruff" },
      },
      linters = {
        mypy = {
          args = {
            "--config-file",
            vim.fn.getcwd() .. "/pyproject.toml",
            "--show-column-numbers",
            "--show-error-end",
            "--hide-error-codes",
            "--hide-error-context",
            "--no-color-output",
            "--no-error-summary",
            "--no-pretty",
          },
        },
      },
    },
  },

  -- DAP for debugging
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "mfussenegger/nvim-dap-python",
    },
    config = function()
      local dap = require("dap")
      local dap_python = require("dap-python")

      -- Setup dap-python with uv's python
      local function get_python_path()
        -- Try to find python in .venv managed by uv
        local venv_path = vim.fn.getcwd() .. "/.venv/bin/python"
        if vim.fn.executable(venv_path) == 1 then
          return venv_path
        end

        -- Fallback to system python
        return "python3"
      end

      dap_python.setup(get_python_path())

      -- Add custom configurations
      table.insert(dap.configurations.python, {
        type = "python",
        request = "launch",
        name = "Launch file with arguments",
        program = "${file}",
        args = function()
          local args_string = vim.fn.input("Arguments: ")
          return vim.split(args_string, " +")
        end,
        console = "integratedTerminal",
      })
    end,
  },

  -- DAP UI for better debugging experience
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    keys = {
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "DAP UI",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval()
        end,
        desc = "Eval",
        mode = { "n", "v" },
      },
    },
    opts = {},
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup(opts)
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },

  -- Neotest for testing
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-python",
    },
    opts = {
      adapters = {
        ["neotest-python"] = {
          dap = { justMyCode = false },
          args = { "--log-level", "DEBUG" },
          runner = "pytest",
          python = function()
            local venv_path = vim.fn.getcwd() .. "/.venv/bin/python"
            if vim.fn.executable(venv_path) == 1 then
              return venv_path
            end
            return "python3"
          end,
        },
      },
    },
  },

  -- Additional Python-specific key mappings
  {
    "neovim/nvim-lspconfig",
    keys = {
      {
        "<leader>co",
        function()
          vim.lsp.buf.code_action({
            apply = true,
            context = {
              only = { "source.organizeImports" },
              diagnostics = {},
            },
          })
        end,
        desc = "Organize Imports",
        mode = "n",
      },
    },
  },

  -- Virtual environments selector
  {
    "linux-cultist/venv-selector.nvim",
    cmd = "VenvSelect",
    opts = {
      name = { ".venv", "venv" },
      auto_refresh = true,
      search_venv_managers = true,
      search_workspace = true,
      dap_enabled = true,
    },
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
    },
  },

  -- Better Python syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "python", "rst", "toml" })
      end
    end,
  },

  -- Python docstrings
  {
    "danymat/neogen",
    keys = {
      {
        "<leader>cn",
        function()
          require("neogen").generate()
        end,
        desc = "Generate Docstring",
      },
    },
    opts = {
      snippet_engine = "luasnip",
      languages = {
        python = {
          template = {
            annotation_convention = "google_docstrings",
          },
        },
      },
    },
  },

  -- Auto-completion with Python-specific sources
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
    },
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.sources = cmp.config.sources({
        { name = "nvim_lsp", priority = 1000 },
        { name = "luasnip", priority = 750 },
        { name = "buffer", priority = 500 },
        { name = "path", priority = 250 },
      })
    end,
  },

  -- UV commands integration
  {
    "nvim-lua/plenary.nvim",
    keys = {
      {
        "<leader>cua",
        function()
          local package = vim.fn.input("Package to add: ")
          if package ~= "" then
            vim.cmd("terminal uv add " .. package)
          end
        end,
        desc = "UV Add Package",
      },
      {
        "<leader>cur",
        function()
          local package = vim.fn.input("Package to remove: ")
          if package ~= "" then
            vim.cmd("terminal uv remove " .. package)
          end
        end,
        desc = "UV Remove Package",
      },
      {
        "<leader>cus",
        function()
          vim.cmd("terminal uv sync")
        end,
        desc = "UV Sync",
      },
      {
        "<leader>cuu",
        function()
          vim.cmd("terminal uv lock --upgrade")
        end,
        desc = "UV Update Lock",
      },
      {
        "<leader>cur",
        function()
          vim.cmd("terminal uv run %")
        end,
        desc = "UV Run Current File",
      },
    },
  },

  -- Additional useful plugins for Python development
  {
    "folke/which-key.nvim",
    opts = {
      defaults = {
        { "<leader>c", group = "code" },
        { "<leader>cu", group = "uv" },
        { "<leader>d", group = "debug" },
        { "<leader>t", group = "test" },
      },
    },
  },

  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        hidden = true, -- for hidden files
        ignored = true, -- for .gitignore files
      },
    },
  },
}
