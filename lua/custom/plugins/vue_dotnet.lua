return {
  -- Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    config = function()
      local ft = {
        'bash',
        'c',
        'diff',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'vim',
        'vimdoc',
        'typescript',
        'javascript',
        'vue',
        'css',
        'json',
        'c_sharp',
      }
      require('nvim-treesitter').install(ft)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = ft,
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
  },

  -- Mason: install LSP servers + formatters
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = {
      ensure_installed = {
        'vue-language-server', -- volar (Vue 3)
        'typescript-language-server', -- ts_ls
        'omnisharp', -- C# / .NET
        'prettier', -- JS/TS/Vue/JSON
        'csharpier', -- C#
        'netcoredbg', -- .NET debugger
      },
    },
  },

  -- LSP servers (Hybrid Mode: ts_ls + vue_ls together)
  {
    'neovim/nvim-lspconfig',
    config = function()
      local cap = require('blink.cmp').get_lsp_capabilities()
      local volar_path = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/language-server'

      vim.lsp.config('ts_ls', {
        capabilities = cap,
        init_options = {
          plugins = {
            { name = '@vue/typescript-plugin', location = volar_path, languages = { 'vue' } },
          },
        },
        filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
      })
      vim.lsp.config('vue_ls', { capabilities = cap })
      vim.lsp.config('omnisharp', {
        capabilities = cap,
        enable_roslyn_analyzers = true,
        organize_imports_on_format = true,
        enable_import_completion = true,
        on_init = function(client)
          -- write_error is called before the user on_error cb, so patch it directly
          -- to suppress the spurious INVALID_SERVER_MESSAGE noise OmniSharp emits on startup
          local orig = client.write_error
          client.write_error = function(self, code, err)
            if code == vim.lsp.rpc.client_errors.INVALID_SERVER_MESSAGE then return end
            orig(self, code, err)
          end
          -- OmniSharp's semantic tokens implementation is also buggy; disable it
          client.server_capabilities.semanticTokensProvider = nil
        end,
      })
      vim.lsp.enable { 'ts_ls', 'vue_ls', 'omnisharp', 'lua_ls' }
    end,
  },

  -- Formatters
  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        javascript = { 'prettier' },
        typescript = { 'prettier' },
        vue = { 'prettier' },
        json = { 'prettier' },
        css = { 'prettier' },
        cs = { 'csharpier' },
      },
    },
  },

  -- Debugger
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio', -- required by dap-ui
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      -- netcoredbg adapter
      dap.adapters.coreclr = {
        type = 'executable',
        command = vim.fn.stdpath 'data' .. '/mason/packages/netcoredbg/netcoredbg',
        args = { '--interpreter=vscode' },
      }

      -- C# launch config — auto-detects the dll, falls back to prompt
      dap.configurations.cs = {
        {
          type = 'coreclr',
          name = 'Launch',
          request = 'launch',
          program = function()
            local cwd = vim.fn.getcwd()
            local dlls = {}
            local all = vim.fn.glob(cwd .. '/**/bin/Debug/net8.0/*.dll', false, true)
            for _, dll in ipairs(all) do
              local project = dll:match '.*/([^/]+)/bin/'
              local name    = dll:match '/([^/]+)%.dll$'
              if project and name == project then
                table.insert(dlls, dll)
              end
            end
            if #dlls == 1 then return dlls[1] end
            return vim.fn.input('Path to dll: ', dlls[1] or (cwd .. '/'), 'file')
          end,
        },
      }

      -- Open/close UI automatically with debug session
      dapui.setup()
      dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
      dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
      dap.listeners.before.event_exited['dapui_config'] = function() dapui.close() end

      -- Keybindings
      vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start / Continue' })
      vim.keymap.set('n', '<F10>', dap.step_over, { desc = 'Debug: Step Over' })
      vim.keymap.set('n', '<F11>', dap.step_into, { desc = 'Debug: Step Into' })
      vim.keymap.set('n', '<F12>', dap.step_out, { desc = 'Debug: Step Out' })
      vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
      vim.keymap.set('n', '<leader>dB', function()
        dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end, { desc = 'Debug: Conditional Breakpoint' })
      vim.keymap.set('n', '<leader>du', dapui.toggle, { desc = 'Debug: Toggle UI' })
    end,
  },
}
