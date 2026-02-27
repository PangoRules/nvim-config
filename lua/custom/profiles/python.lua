-- Python profile
return {
  treesitter = { 'python' },

  mason = {
    'pyright',  -- LSP
    'black',    -- formatter
    'ruff',     -- linter / fast fixer
  },

  servers = { 'pyright' },

  -- ruff_fix runs first (fixes lint issues), black formats after
  formatters = {
    python = { 'ruff_fix', 'black' },
  },
}
