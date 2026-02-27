-- React / TypeScript profile
return {
  treesitter = { 'typescript', 'javascript', 'tsx', 'css', 'json' },

  mason = {
    'typescript-language-server',
    'prettier',
    'eslint-lsp',
  },

  servers = { 'ts_ls', 'eslint' },

  -- prettier formats; ESLint fixes are applied via LSP code actions (<leader>ca)
  formatters = {
    javascript      = { 'prettier' },
    typescript      = { 'prettier' },
    javascriptreact = { 'prettier' },
    typescriptreact = { 'prettier' },
    json            = { 'prettier' },
    css             = { 'prettier' },
  },
}
