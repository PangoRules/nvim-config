-- REST client profile: kulala.nvim for .http file execution
return {
  treesitter = { 'http', 'json' },

  mason = {},

  extra_specs = {
    {
      'mistweaverco/kulala.nvim',
      ft = 'http',
      opts = {
        default_view = 'body',
        default_env  = 'dev',
      },
      config = function(_, opts)
        local kulala = require 'kulala'
        kulala.setup(opts)

        local k = vim.keymap.set

        local function attach(buf)
          require('which-key').add { { '<leader>R', group = '[R]EST', buffer = buf } }
          k('n', '<leader>Rr', kulala.run,             { buffer = buf, desc = 'REST: Run request' })
          k('n', '<leader>Ra', kulala.run_all,         { buffer = buf, desc = 'REST: Run all' })
          k('n', '<leader>Rn', kulala.jump_next,       { buffer = buf, desc = 'REST: Next request' })
          k('n', '<leader>Rp', kulala.jump_prev,       { buffer = buf, desc = 'REST: Previous request' })
          k('n', '<leader>Rt', kulala.toggle_view,     { buffer = buf, desc = 'REST: Toggle body/headers' })
          k('n', '<leader>Rc', kulala.copy,             { buffer = buf, desc = 'REST: Copy as curl' })
          k('n', '<leader>Re', kulala.set_selected_env,{ buffer = buf, desc = 'REST: Select environment' })
          k('n', '<leader>Ri', kulala.inspect,         { buffer = buf, desc = 'REST: Inspect request' })
        end

        vim.api.nvim_create_autocmd('FileType', {
          pattern  = 'http',
          callback = function(ev) attach(ev.buf) end,
        })

        -- The FileType event for the buffer that triggered this load already
        -- fired before the plugin was available — attach keymaps to it now.
        if vim.bo.filetype == 'http' then
          attach(vim.api.nvim_get_current_buf())
        end
      end,
    },
  },
}
