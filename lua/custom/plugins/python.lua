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
        'python',
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
        'pyright', -- LSP
        'black', -- formatter
        'ruff', -- linter/formatter
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      local cap = require('blink.cmp').get_lsp_capabilities()
      vim.lsp.config('pyright', { capabilities = cap })
      vim.lsp.enable { 'pyright', 'lua_ls' }
    end,
  },
  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        python = { 'black' },
      },
    },
  },
}
