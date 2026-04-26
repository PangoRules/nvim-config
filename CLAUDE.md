# CLAUDE.md — Neovim Config Context

Custom Neovim config built on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).
Plugin manager: lazy.nvim. Full user-facing reference: `USAGE.md`.

## Architecture

Single `init.lua` + a composable profile system. Profiles gate language tooling (LSP,
Treesitter, formatters, DAP) behind the `NVIM_PROFILE` env var. No profile → no language
plugins load at all.

```
init.lua                          # options, keymaps, always-on plugins, lazy.setup()
lua/custom/
  plugins/init.lua                # profile loader — reads NVIM_PROFILE, returns lazy specs
  profiles/
    python.lua / node.lua / react.lua / vue.lua / dotnet.lua
  terminal.lua                    # M.float_term(cmd), M.bg_job(cmd, label)
```

## Profile System (`lua/custom/plugins/init.lua`)

`build_specs(raw)` is the entry point. It:
1. Splits `NVIM_PROFILE` on commas, trims whitespace.
2. `pcall(require, 'custom.profiles.<name>')` for each — warns + skips unknown names.
3. Collects `treesitter`, `mason`, LSP setup functions, `formatters`, `extra_specs` from
   each profile into shared lists.
4. Dedupes parsers and tools (`dedupe()` — multiple profiles can list `typescript`).
5. Returns a flat list of lazy.nvim specs: one Treesitter, one Mason, one nvim-lspconfig,
   one conform, plus all `extra_specs`.

`vim.schedule()` wraps the startup notify — the UI isn't ready during plugin loading.

## Two LSP Strategies

| Field | When to use |
|-------|-------------|
| `servers = { 'name' }` + optional `lsp_overrides` | Server only needs `capabilities`. Uses `simple_lsp()` internally. |
| `lsp_setup = function(cap) … return { 'name' } end` | Server needs `init_options`, extra `filetypes`, or custom callbacks. |

`lua_ls` is hardcoded always-on inside `build_specs` regardless of profile.

## Always-On (no profile needed)

**LSP:** `lua_ls`, `dockerls`, `docker_compose_language_service`
**Treesitter:** `bash c diff html lua luadoc markdown markdown_inline query sql vim vimdoc` + `dockerfile yaml` (via Docker plugin)
**Formatters (conform):** `lua → stylua`, `sql → sql_formatter`
**Completion sources (blink.cmp):** `dadbod` source active for `sql/mysql/plsql` ft

## Profile Inventory

| Profile | LSP strategy | Servers | Formatter | Extra specs |
|---------|-------------|---------|-----------|-------------|
| `python` | `servers` | `pyright` | `ruff_fix`, `ruff_format` | — |
| `node` | `servers` | `ts_ls`, `eslint` | `prettier` | — |
| `react` | `servers` | `ts_ls`, `eslint` | `prettier` | — |
| `vue` | `lsp_setup` | `ts_ls`, `vue_ls` | `prettier` | — |
| `dotnet` | none (roslyn.nvim auto-attaches on `ft=cs`) | roslyn | `csharpier` | roslyn.nvim, nvim-dap + dapui + dap-virtual-text, neotest + neotest-dotnet |
| `rest` | none | — | — | kulala.nvim (`ft=http`), buffer-local `<leader>R*` keymaps via FileType autocmd + first-buf guard |

**Vue hybrid mode:** `ts_ls` + `vue_ls` run together. `@vue/typescript-plugin` is registered
in `ts_ls.init_options` (location = Mason's volar package). `ts_ls.filetypes` is extended to
include `vue`.

**Dotnet DAP:** adapter name = `coreclr`, binary at `stdpath('data')/mason/packages/netcoredbg/netcoredbg`.
DLL auto-discovery globs `**/bin/Debug/net*/*.dll` and matches filename == parent folder name.
DAP UI auto-opens/closes via `event_initialized` / `event_terminated` / `event_exited` listeners.

## Key Binding Groups (leader = `<space>`)

| Prefix | Group |
|--------|-------|
| `<leader>s*` | Telescope search |
| `<leader>h*` | Harpoon (h1–h4 jump, hc1–hc4 clear, hr1–hr4 replace) |
| `<leader>g*` | Git (Neogit + Diffview) |
| `<leader>D*` | Docker |
| `<leader>Q*` | Database (vim-dadbod-ui) |
| `<leader>R*` | REST — rest profile only, buffer-local on `.http` files |
| `<leader>x*` | Diagnostics / Trouble |
| `<leader>d*` | Debug — dotnet profile only |
| `<leader>dw*` | Debug watch/scope floats |
| `<leader>dt*` | Neotest |
| `z R/M/K` | Folding (nvim-ufo) |

## Coding Conventions

- `local k = vim.keymap.set` shorthand used inside config functions.
- Prefer explicit `k()` calls per binding over loops — keeps each binding readable at a glance.
- Roslyn LSP settings keys use `'section|subsection'` format (LSP server convention, not Lua).
- `terminal.lua` helpers used for Docker float/bg commands; also available in `.nvim.lua`.

## Adding a New Profile

1. Create `lua/custom/profiles/<name>.lua` returning a table with any subset of:
   `treesitter`, `mason`, `servers`/`lsp_overrides` OR `lsp_setup`, `formatters`, `extra_specs`.
2. No registration needed — the loader discovers by `NVIM_PROFILE` name at runtime.
3. Add a shell alias: `alias nvim-X='NVIM_PROFILE=X nvim'`.

## Things That Are Easy to Get Wrong

- `vim.opt.scrolloff` and `vim.o.scrolloff` are aliases; setting both in sequence means the
  last one wins. Only one should exist (`vim.o.scrolloff = 10`).
- `simple_lsp` returns server names — the caller must pass them to `vim.lsp.enable()`.
  `lsp_setup` functions also return names for the same reason.
- `vim.lsp.config()` must be called before `vim.lsp.enable()` — config just registers settings,
  enable actually starts the server.
- New profiles should not call `vim.lsp.enable()` themselves; the loader does it centrally.
- `extra_specs` items are raw lazy.nvim spec tables — they go through the full lazy lifecycle
  (dependencies, ft-lazy-loading, etc.).
