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

        vim.api.nvim_create_autocmd('FileType', {
          pattern  = 'http',
          callback = function()
            require('which-key').add { { '<leader>R', group = '[R]EST', buffer = true } }
            k('n', '<leader>Rr', kulala.run,             { buffer = true, desc = 'REST: Run request' })
            k('n', '<leader>Ra', kulala.run_all,          { buffer = true, desc = 'REST: Run all' })
            k('n', '<leader>Rn', kulala.jump_next,        { buffer = true, desc = 'REST: Next request' })
            k('n', '<leader>Rp', kulala.jump_prev,        { buffer = true, desc = 'REST: Previous request' })
            k('n', '<leader>Rt', kulala.toggle_view,      { buffer = true, desc = 'REST: Toggle body/headers' })
            k('n', '<leader>Rc', kulala.copy_as_curl,     { buffer = true, desc = 'REST: Copy as curl' })
            k('n', '<leader>Re', kulala.set_selected_env, { buffer = true, desc = 'REST: Select environment' })
            k('n', '<leader>Ri', kulala.inspect,          { buffer = true, desc = 'REST: Inspect request' })
          end,
        })
      end,
    },
  },
}
