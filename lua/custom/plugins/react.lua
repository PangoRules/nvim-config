return {
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
        'tsx',
        'css',
        'json',
      }
      require('nvim-treesitter').install(ft)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = ft,
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = {
      ensure_installed = {
        'typescript-language-server',
        'prettier',
        'eslint_d',
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      local cap = require('blink.cmp').get_lsp_capabilities()
      vim.lsp.config('ts_ls', { capabilities = cap })
      vim.lsp.enable { 'ts_ls', 'lua_ls' }
    end,
  },
  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        javascript = { 'prettier' },
        typescript = { 'prettier' },
        json = { 'prettier' },
        css = { 'prettier' },
      },
    },
  },
}
