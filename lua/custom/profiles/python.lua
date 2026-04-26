-- Python profile
return {
  treesitter = { 'python', 'toml' },

  mason = {
    'pyright', -- LSP
    'ruff',    -- linter + formatter (replaces black)
  },

  servers = { 'pyright' },

  -- ruff_fix applies lint auto-fixes first, ruff_format formats after
  formatters = {
    python = { 'ruff_fix', 'ruff_format' },
  },
}
