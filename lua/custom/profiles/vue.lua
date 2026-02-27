-- Vue 3 + TypeScript profile (Hybrid Mode: ts_ls + vue_ls together)
return {
  treesitter = { 'typescript', 'javascript', 'vue', 'css', 'json' },

  mason = {
    'vue-language-server',        -- volar
    'typescript-language-server', -- ts_ls
    'prettier',
  },

  lsp_setup = function(cap)
    local volar_path = vim.fn.stdpath 'data'
      .. '/mason/packages/vue-language-server/node_modules/@vue/language-server'

    vim.lsp.config('ts_ls', {
      capabilities  = cap,
      init_options  = {
        plugins = {
          { name = '@vue/typescript-plugin', location = volar_path, languages = { 'vue' } },
        },
      },
      filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
    })
    vim.lsp.config('vue_ls', { capabilities = cap })

    return { 'ts_ls', 'vue_ls' }
  end,

  formatters = {
    javascript = { 'prettier' },
    typescript = { 'prettier' },
    vue        = { 'prettier' },
    json       = { 'prettier' },
    css        = { 'prettier' },
  },
}
