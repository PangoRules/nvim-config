# Nvim Profile: nuxt-dotnet-py

**Date:** 2026-04-25
**Scope:** nvim config (`~/.config/nvim`), dotfiles (`~/dotfiles`), per-project `.nvim-profile` files

## Summary

Add a reusable Neovim profile for full-stack monorepo projects combining Nuxt 3 (Vue 3 + TypeScript), ASP.NET Core (C#), and Python. First use: `cook-homie`. Covers four changes:

1. Shell alias `nvim-nuxt-dotnet-py` in dotfiles
2. Auto-activation via `.nvim-profile` file read by `init.lua` at startup
3. Python profile improvements (ruff format, TOML treesitter)
4. `kulala.nvim` REST client added to the profile

---

## Architecture

No new composite profile file is needed. The profile system supports additive composition via comma-separated `NVIM_PROFILE` values. `nuxt-dotnet-py` is `vue,dotnet,python,rest` — four existing/new profiles merged at load time.

The new work lives in:
- `~/dotfiles/shell/.zshrc` — alias
- `~/dotfiles/git/ignore` — add `.nvim-profile` to global gitignore
- `~/.config/nvim/init.lua` — auto-detection patch
- `~/.config/nvim/lua/custom/profiles/python.lua` — ruff + toml improvements
- `~/.config/nvim/lua/custom/profiles/rest.lua` — new profile: kulala.nvim + REST keymaps
- `~/Projects/cook-homie/.nvim-profile` — project file containing `vue,dotnet,python,rest`

---

## Components

### 1. Shell alias

**File:** `~/dotfiles/shell/.zshrc`

```zsh
alias nvim-nuxt-dotnet-py='NVIM_PROFILE=vue,dotnet,python,rest nvim'
```

Follows the existing `nvim-` naming convention. Reusable for any future Nuxt + .NET + Python monorepo.

### 2. Auto-activation via `.nvim-profile`

**File:** `~/.config/nvim/init.lua` (before lazy.nvim setup)

```lua
if (vim.env.NVIM_PROFILE or '') == '' then
  local f = vim.fn.findfile('.nvim-profile', '.;')
  if f ~= '' then
    vim.env.NVIM_PROFILE = vim.trim(vim.fn.readfile(f)[1] or '')
  end
end
```

**Behaviour:**
- Only runs when `NVIM_PROFILE` is not already set — explicit alias/env var always wins
- `findfile('.nvim-profile', '.;')` walks up from cwd, so it works from any subdirectory of the project
- Reads the first line of the file as the profile string (e.g. `vue,dotnet,python`)
- Silent no-op if no `.nvim-profile` exists anywhere in the tree

**Per-project file:** `<project-root>/.nvim-profile`
```
vue,dotnet,python,rest
```

Add `.nvim-profile` to the global gitignore (`~/dotfiles/git/ignore`) so it never leaks into repos accidentally. Projects that want to commit it can override via their own `.gitignore`.

### 3. Python profile improvements

**File:** `~/.config/nvim/lua/custom/profiles/python.lua`

Changes:
- Add `toml` to `treesitter` parsers — covers `pyproject.toml` and any other TOML config files
- Replace `black` + `ruff_fix` with `ruff_fix` + `ruff_format` — ruff's built-in formatter is production-ready, faster, and eliminates one mason tool

```lua
return {
  treesitter = { 'python', 'toml' },
  mason = { 'pyright', 'ruff' },
  servers = { 'pyright' },
  formatters = {
    python = { 'ruff_fix', 'ruff_format' },
  },
}
```

### 4. kulala.nvim — REST client

A new `rest.lua` profile keeps the REST client self-contained and reusable in any project that needs API testing, independent of the language stack.

**File:** `~/.config/nvim/lua/custom/profiles/rest.lua`

```lua
return {
  treesitter = { 'http', 'json' },
  mason = {},
  extra_specs = {
    {
      'mistweaverco/kulala.nvim',
      ft = 'http',
      opts = { default_view = 'body', default_env = 'dev' },
      config = function(_, opts)
        local kulala = require 'kulala'
        kulala.setup(opts)
        local k = vim.keymap.set

        vim.api.nvim_create_autocmd('FileType', {
          pattern = 'http',
          callback = function()
            -- Register which-key group buffer-locally so it only shows on .http files
            require('which-key').add { { '<leader>R', group = '[R]EST', buffer = true } }
            k('n', '<leader>Rr', kulala.run,             { buffer = true, desc = 'REST: Run request' })
            k('n', '<leader>Ra', kulala.run_all,          { buffer = true, desc = 'REST: Run all' })
            k('n', '<leader>Rn', kulala.jump_next,        { buffer = true, desc = 'REST: Next request' })
            k('n', '<leader>Rp', kulala.jump_prev,        { buffer = true, desc = 'REST: Previous request' })
            k('n', '<leader>Rt', kulala.toggle_view,      { buffer = true, desc = 'REST: Toggle body/headers' })
            k('n', '<leader>Rc', kulala.copy_as_curl,     { buffer = true, desc = 'REST: Copy as curl' })
            k('n', '<leader>Re', kulala.set_selected_env, { buffer = true, desc = 'REST: Select environment' })
            k('n', '<leader>Rl', kulala.show_stats,       { buffer = true, desc = 'REST: View logs/stats' })
          end,
        })
      end,
    },
  },
}
```

**Keymap table (all buffer-local, only on `ft=http`):**

| Keymap | Description |
|---|---|
| `<leader>Rr` | Run request under cursor |
| `<leader>Ra` | Run all requests in file |
| `<leader>Rn` | Next request |
| `<leader>Rp` | Previous request |
| `<leader>Rt` | Toggle body / headers view |
| `<leader>Rc` | Copy as curl command |
| `<leader>Re` | Select environment |
| `<leader>Rl` | View logs / stats |

---

## Data Flow

```
nvim launched from project dir
  → init.lua: NVIM_PROFILE unset?
      → findfile('.nvim-profile', '.;') → found → set NVIM_PROFILE=vue,dotnet,python,rest
  → lazy.nvim setup → require('custom.plugins')
      → build_specs reads NVIM_PROFILE, loads vue + dotnet + python + rest profiles
      → merges treesitter parsers, mason tools, LSP setups, formatters, extra_specs
  → all four stacks active in one session
```

---

## Testing

- Open nvim from `~/Projects/cook-homie/src/CookHomie.Web/` (subdirectory) — confirm profile loads
- Open a `.vue` file — confirm vue_ls + ts_ls attach
- Open a `.cs` file — confirm roslyn attaches, CSharpier formats on save
- Open a `.py` file — confirm pyright attaches, ruff formats on save
- Open a `.toml` file — confirm TOML syntax highlighting
- Create `tests/api.http`, write a request, `<leader>Rr` — confirm response appears
- Open nvim from a non-cook-homie dir with no `.nvim-profile` — confirm no profile loads (blank session)
- Run `nvim-nuxt-dotnet-py` from any directory — confirm all four profiles activate

---

## Files Changed

| File | Change |
|---|---|
| `~/dotfiles/shell/.zshrc` | Add `nvim-nuxt-dotnet-py` alias |
| `~/dotfiles/git/ignore` | Add `.nvim-profile` to global gitignore |
| `~/.config/nvim/init.lua` | Add `.nvim-profile` auto-detection block |
| `~/.config/nvim/lua/custom/profiles/python.lua` | ruff_format + toml treesitter |
| `~/.config/nvim/lua/custom/profiles/rest.lua` | New — kulala.nvim + REST keymaps |
| `~/Projects/cook-homie/.nvim-profile` | New — `vue,dotnet,python,rest` |
