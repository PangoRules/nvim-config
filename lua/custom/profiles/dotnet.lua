-- C# / .NET profile: roslyn.nvim LSP + CSharpier formatter + netcoredbg DAP + neotest
return {
  treesitter = { 'c_sharp' },

  mason = {
    'roslyn',    -- C# LSP (from github:Crashdummyy/mason-registry)
    'csharpier', -- C# formatter
    'netcoredbg', -- .NET debugger
  },

  -- No lsp_setup: roslyn.nvim auto-attaches on ft=cs
  formatters = {
    cs = { 'csharpier' },
  },

  extra_specs = {
    {
      'seblyng/roslyn.nvim',
      ft = 'cs',
      opts = function()
        local ok, blink = pcall(require, 'blink.cmp')
        local cap = ok and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()
        return {
          config = {
            capabilities = cap,
            settings = {
              ['csharp|inlay_hints'] = {
                csharp_enable_inlay_hints_for_implicit_variable_types = true,
                csharp_enable_inlay_hints_for_types = true,
                dotnet_enable_inlay_hints_for_parameters = true,
                dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
                dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
              },
              ['csharp|completion'] = {
                dotnet_show_completion_items_from_unimported_namespaces = true,
                dotnet_show_name_completion_suggestions = true,
              },
              ['csharp|code_lens'] = {
                dotnet_enable_references_code_lens = true,
              },
            },
          },
        }
      end,
    },

    {
      'theHamsta/nvim-dap-virtual-text',
      opts = { enabled = true },
    },

    {
      'mfussenegger/nvim-dap',
      dependencies = {
        'rcarriga/nvim-dap-ui',
        'nvim-neotest/nvim-nio',
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

        -- C# launch config — auto-detects the project dll, falls back to prompt
        dap.configurations.cs = {
          {
            type = 'coreclr',
            name = 'Launch',
            request = 'launch',
            program = function()
              local cwd = vim.fn.getcwd()
              local dlls = {}
              local all = vim.fn.glob(cwd .. '/**/bin/Debug/net*/*.dll', false, true)
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
              local all = vim.fn.glob(root .. '/**/bin/Debug/net*/*.dll', false, true)
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

        dapui.setup()
        dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
        dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
        dap.listeners.before.event_exited['dapui_config'] = function() dapui.close() end

        require('which-key').add {
          { '<leader>d',  group = '[D]ebug' },
          { '<leader>dw', group = '[D]ebug [W]atch' },
        }
        local k = vim.keymap.set
        local widgets = require 'dap.ui.widgets'

        local bindings = {
          { '<F5>',       dap.continue,          'Start / Continue' },
          { '<F10>',      dap.step_over,          'Step Over' },
          { '<F11>',      dap.step_into,          'Step Into' },
          { '<F12>',      dap.step_out,           'Step Out' },
          { '<leader>db', dap.toggle_breakpoint,  'Toggle Breakpoint' },
          { '<leader>du', dapui.toggle,           'Toggle UI' },
          { '<leader>dr', dap.restart,            'Restart' },
          { '<leader>dc', dap.run_to_cursor,      'Run to Cursor' },
          { '<leader>dl', dap.run_last,           'Run Last' },
        }
        for _, b in ipairs(bindings) do
          k('n', b[1], b[2], { desc = 'Debug: ' .. b[3] })
        end

        k('n', '<leader>dB', function()
          dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end, { desc = 'Debug: Conditional Breakpoint' })
        k('n', '<leader>dbc', function() dap.clear_breakpoints() end, { desc = 'Debug: Clear all Breakpoints' })

        -- QuickWatch: evaluate word under cursor (or visual selection) in a float
        k('n', '<leader>dwe', function() dapui.eval() end,                  { desc = 'Debug: Eval under cursor' })
        k('v', '<leader>dwe', function() dapui.eval() end,                  { desc = 'Debug: Eval selection' })

        -- Hover widget: inline float with current value (lighter than eval)
        k('n', '<leader>dwh', function() widgets.hover() end,               { desc = 'Debug: Hover variable' })
        k('v', '<leader>dwh', function() widgets.hover() end,               { desc = 'Debug: Hover selection' })

        -- Open watches panel focused so you can press `a` to add, `d` to delete
        k('n', '<leader>dww', function()
          dapui.float_element('watches', { enter = true })
        end, { desc = 'Debug: Watches panel' })

        -- Scopes panel (Locals) in a float — useful when the sidebar is too narrow
        k('n', '<leader>dws', function()
          dapui.float_element('scopes', { enter = true })
        end, { desc = 'Debug: Scopes float (Locals)' })
      end,
    },

    {
      'nvim-neotest/neotest',
      dependencies = {
        'nvim-neotest/nvim-nio',
        'nvim-lua/plenary.nvim',
        'antoinemadec/FixCursorHold.nvim',
        'nvim-treesitter/nvim-treesitter',
        'Issafalcon/neotest-dotnet',
      },
      config = function()
        require('neotest').setup {
          adapters = {
            require('neotest-dotnet') {
              dap = { adapter_name = 'coreclr' },
              -- discovers tests project-by-project (better for solutions with multiple test projects)
              discovery_root = 'project',
            },
          },
        }

        require('which-key').add { { '<leader>dt', group = '[D]ebug [T]ests' } }

        local nt = require 'neotest'
        local k = vim.keymap.set
        local o = { noremap = true, silent = true }
        local d = function(desc) return vim.tbl_extend('force', o, { desc = 'Test: ' .. desc }) end

        -- Run
        k('n', '<leader>dtt', function() nt.run.run() end,                           d 'Run nearest')
        k('n', '<leader>dtf', function() nt.run.run(vim.fn.expand '%') end,          d 'Run file')
        k('n', '<leader>dta', function() nt.run.run { suite = true } end,            d 'Run all')
        k('n', '<leader>dtl', function() nt.run.run_last() end,                      d 'Run last')
        k('n', '<leader>dtw', function() nt.watch.toggle(vim.fn.expand '%') end,     d 'Watch file')

        -- Debug (hooks into netcoredbg via coreclr adapter)
        k('n', '<leader>dtd', function() nt.run.run { strategy = 'dap' } end,        d 'Debug nearest')

        -- UI
        k('n', '<leader>dts', function() nt.summary.toggle() end,                    d 'Toggle summary')
        k('n', '<leader>dto', function() nt.output.open { enter = true } end,        d 'Open output')
        k('n', '<leader>dtp', function() nt.output_panel.toggle() end,               d 'Toggle output panel')
      end,
    },
  },
}
