-- Node.js / TypeScript profile (no JSX)
return {
  treesitter = { 'typescript', 'javascript', 'json' },

  mason = {
    'typescript-language-server',
    'prettier',
    'eslint-lsp',
  },

  servers = { 'ts_ls', 'eslint' },

  -- prettier formats; ESLint fixes are applied via LSP code actions (<leader>ca)
  formatters = {
    javascript = { 'prettier' },
    typescript = { 'prettier' },
    json       = { 'prettier' },
  },
}
