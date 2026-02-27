-- C# / .NET profile: OmniSharp LSP + CSharpier formatter + netcoredbg DAP
return {
  treesitter = { 'c_sharp' },

  mason = {
    'omnisharp',    -- C# LSP
    'csharpier',    -- C# formatter
    'netcoredbg',   -- .NET debugger
  },

  lsp_setup = function(cap)
    vim.lsp.config('omnisharp', {
      capabilities             = cap,
      enable_roslyn_analyzers  = true,
      organize_imports_on_format = true,
      enable_import_completion = true,
      on_init = function(client)
        -- Suppress spurious INVALID_SERVER_MESSAGE noise OmniSharp emits on startup
        local orig = client.write_error
        client.write_error = function(self, code, err)
          if code == vim.lsp.rpc.client_errors.INVALID_SERVER_MESSAGE then return end
          orig(self, code, err)
        end
        -- OmniSharp semantic tokens are buggy; disable them
        client.server_capabilities.semanticTokensProvider = nil
      end,
    })
    return { 'omnisharp' }
  end,

  formatters = {
    cs = { 'csharpier' },
  },

  extra_specs = {
    {
      'theHamsta/nvim-dap-virtual-text',
      opts = { enabled = true },
    },
    {
      'mfussenegger/nvim-dap',
      dependencies = {
        'rcarriga/nvim-dap-ui',
        'nvim-neotest/nvim-nio', -- required by dap-ui
      },
      config = function()
        local dap   = require 'dap'
        local dapui = require 'dapui'

        -- netcoredbg adapter
        dap.adapters.coreclr = {
          type    = 'executable',
          command = vim.fn.stdpath 'data' .. '/mason/packages/netcoredbg/netcoredbg',
          args    = { '--interpreter=vscode' },
        }

        -- C# launch config — auto-detects the project dll, falls back to prompt
        dap.configurations.cs = {
          {
            type    = 'coreclr',
            name    = 'Launch',
            request = 'launch',
            program = function()
              local cwd  = vim.fn.getcwd()
              local dlls = {}
              local all  = vim.fn.glob(cwd .. '/**/bin/Debug/net*/*.dll', false, true)
              for _, dll in ipairs(all) do
                local project = dll:match '.*/([^/]+)/bin/'
                local dllname = dll:match '/([^/]+)%.dll$'
                if project and dllname == project then table.insert(dlls, dll) end
              end
              if #dlls == 1 then return dlls[1] end
              return vim.fn.input('Path to dll: ', dlls[1] or (cwd .. '/'), 'file')
            end,
            cwd = function()
              local root = vim.fn.getcwd()
              local all  = vim.fn.glob(root .. '/**/bin/Debug/net*/*.dll', false, true)
              for _, dll in ipairs(all) do
                local project = dll:match '.*/([^/]+)/bin/'
                local dllname = dll:match '/([^/]+)%.dll$'
                if project and dllname == project then return dll:match '(.*)/bin/' end
              end
              return root
            end,
            env = { ASPNETCORE_ENVIRONMENT = 'Development' },
          },
        }

        -- Open/close UI automatically with debug session
        dapui.setup()
        dap.listeners.after.event_initialized['dapui_config']  = function() dapui.open() end
        dap.listeners.before.event_terminated['dapui_config']  = function() dapui.close() end
        dap.listeners.before.event_exited['dapui_config']      = function() dapui.close() end

        -- Keybindings
        require('which-key').add { { '<leader>d', group = '[D]ebug' } }
        local k = vim.keymap.set
        local bindings = {
          { '<F5>',        dap.continue,          'Start / Continue' },
          { '<F10>',       dap.step_over,          'Step Over' },
          { '<F11>',       dap.step_into,          'Step Into' },
          { '<F12>',       dap.step_out,           'Step Out' },
          { '<leader>db',  dap.toggle_breakpoint,  'Toggle Breakpoint' },
          { '<leader>du',  dapui.toggle,           'Toggle UI' },
          { '<leader>dr',  dap.restart,            'Restart' },
          { '<leader>dc',  dap.run_to_cursor,      'Run to Cursor' },
          { '<leader>dl',  dap.run_last,           'Run Last' },
        }
        for _, b in ipairs(bindings) do
          k('n', b[1], b[2], { desc = 'Debug: ' .. b[3] })
        end
        k('n', '<leader>dB', function()
          dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end, { desc = 'Debug: Conditional Breakpoint' })
      end,
    },
  },
}
