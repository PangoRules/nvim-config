# Custom Neovim Config — Usage Reference

This config is built on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim), uses
[lazy.nvim](https://github.com/folke/lazy.nvim) for plugin management, and extends it with a
profile system that gates language tooling behind `NVIM_PROFILE`. "Always-on" plugins load
every session; language stacks (LSP, Treesitter, formatters) only load when the matching
profile is active. Everything starts from `init.lua`.

## Directory Layout

```
~/.config/nvim/
├── init.lua                   # Core config, base plugins, Docker integration
└── lua/custom/
    ├── plugins/init.lua       # Profile switcher + simple_lsp helper
    ├── profiles/              # One file per language stack
    │   ├── python.lua
    │   ├── node.lua
    │   ├── react.lua
    │   ├── vue.lua
    │   └── dotnet.lua
    └── terminal.lua           # float_term / bg_job helpers
```

## Shell Setup

Set `NVIM_PROFILE` to a comma-separated list of profile names:

```bash
# ~/.zshrc
alias nvim-python='NVIM_PROFILE=python nvim'
alias nvim-node='NVIM_PROFILE=node nvim'
alias nvim-react='NVIM_PROFILE=react nvim'
alias nvim-vue='NVIM_PROFILE=vue,dotnet nvim'   # combine stacks
alias nvim-dotnet='NVIM_PROFILE=dotnet nvim'
```

Profiles are additive — `vue,dotnet` merges both stacks including DAP.

**Per-project overrides:** place a `.nvim.lua` in the project root; it is auto-loaded via
`exrc` (Neovim 0.9+). Nvim will prompt to trust the file on first open.

## Always-On Plugins

| Plugin | Purpose | Key binding(s) |
|--------|---------|----------------|
| Telescope | Fuzzy finder: files, grep, LSP, help | `<leader>s*`, `<leader>/`, `<leader><leader>` |
| Oil.nvim | File explorer as editable buffer | `-` |
| Harpoon | File bookmarks & quick jump | `<leader>h*` |
| Grug-far | Project-wide find & replace | `<leader>sr` |
| Trouble | Diagnostics / todo panel | `<leader>x*` |
| Neogit + Diffview | Git commit / branch / diff workflow | `<leader>gs` |
| Gitsigns | Git gutter signs (+/~/_ markers) | — |
| Autopairs | Auto-close brackets/quotes (TS-aware) | — (InsertEnter) |
| Conform | Format buffer (also on save) | `<leader>f` |
| Blink.cmp | LSP completion | `<c-y>` accept, `<c-n/p>`, `<c-space>`, `<c-e>`, `<c-k>` |
| Which-key | Pending keymap overlay | — (automatic) |
| Todo-comments | Highlight `TODO/FIXME/NOTE` in code | surfaces via `<leader>xt` |
| Mini.ai | Extended text objects | `va)`, `ci'`, `yinq` |
| Mini.surround | Add/delete/replace surroundings | `sa`, `sd`, `sr` |
| nvim-lspconfig | LSP client (`lua_ls` always on) | `grn`, `gra`, `grr`, `grd`, `gri`, `grt`, `grD`, `gO`, `gW` |
| Docker integration | Dockerfile/compose LSP + keymaps | `<leader>D*` |

## Keymap Reference

### Core / Window Navigation

| Keymap | Mode | Description |
|--------|------|-------------|
| `<C-h/j/k/l>` | n | Move focus between windows |
| `<Esc>` | n | Clear search highlights |
| `<Esc><Esc>` | t | Exit terminal mode |
| `<leader>q` | n | Open diagnostic quickfix list |
| `<leader>th` | n | Toggle inlay hints (LSP, when server supports it) |

### Telescope

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader><leader>` | n | Find open buffers |
| `<leader>sf` | n | Find files |
| `<leader>sg` | n | Live grep |
| `<leader>sw` | n/v | Grep current word / selection |
| `<leader>sd` | n | Search diagnostics |
| `<leader>sh` | n | Search help tags |
| `<leader>sk` | n | Search keymaps |
| `<leader>sc` | n | Search commands |
| `<leader>ss` | n | Select Telescope picker |
| `<leader>sR` | n | Resume last search |
| `<leader>s.` | n | Recent files |
| `<leader>sn` | n | Search Neovim config files |
| `<leader>/` | n | Fuzzy search current buffer |
| `<leader>s/` | n | Grep in open files |

### LSP

| Keymap | Mode | Description |
|--------|------|-------------|
| `grn` | n | Rename symbol |
| `gra` | n/x | Code action |
| `grr` | n | Go to references |
| `grd` | n | Go to definition |
| `gri` | n | Go to implementation |
| `grt` | n | Go to type definition |
| `grD` | n | Go to declaration |
| `gO` | n | Document symbols |
| `gW` | n | Workspace symbols |

### Harpoon

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>h` | n | Open Harpoon menu |
| `<leader>ha` | n | Add current file |
| `<leader>h1`–`h4` | n | Jump to slot 1–4 |
| `<leader>hc1`–`hc4` | n | Clear slot 1–4 |
| `<leader>hr1`–`hr4` | n | Replace slot 1–4 |
| `<leader>hn` | n | Next file |
| `<leader>hp` | n | Previous file |
| `<leader>hca` | n | Clear all slots |

### Docker

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>Dl` | n | lazydocker TUI |
| `<leader>Di` | n | `docker compose up -d` (background) |
| `<leader>Da` | n | `docker compose up` (attached) |
| `<leader>Db` | n | `docker compose up --build` |
| `<leader>Ds` | n | `docker compose down` (background) |
| `<leader>Df` | n | Follow compose logs |
| `<leader>Dp` | n | `docker compose ps` |
| `<leader>De` | n | Edit `.env` |

### File / Search / Replace

| Keymap | Mode | Description |
|--------|------|-------------|
| `-` | n | Open parent dir (Oil) |
| `<leader>f` | n/v | Format buffer (Conform) |
| `<leader>sr` | n/v | Project-wide find & replace (Grug-far) |

### Diagnostics

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>xx` | n | All diagnostics (Trouble) |
| `<leader>xb` | n | Buffer diagnostics (Trouble) |
| `<leader>xq` | n | Quickfix list (Trouble) |
| `<leader>xt` | n | TODOs (Trouble) |

### Git

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>gs` | n | Neogit status |

### Debug (dotnet profile only)

| Keymap | Mode | Description |
|--------|------|-------------|
| `<F5>` | n | Start / Continue |
| `<F10>` | n | Step Over |
| `<F11>` | n | Step Into |
| `<F12>` | n | Step Out |
| `<leader>db` | n | Toggle breakpoint |
| `<leader>dB` | n | Conditional breakpoint |
| `<leader>du` | n | Toggle DAP UI |
| `<leader>dr` | n | Restart |
| `<leader>dc` | n | Run to cursor |
| `<leader>dl` | n | Run last |

## Profile System — How It Works

Each file in `lua/custom/profiles/` returns a table. The loader in `lua/custom/plugins/init.lua`
merges all active profiles and emits a single consolidated set of lazy.nvim specs.

**Profile table fields:**

| Field | Type | Purpose |
|-------|------|---------|
| `treesitter` | `string[]` | Treesitter parsers to install |
| `mason` | `string[]` | Mason tools to ensure installed |
| `servers` | `string[]` | LSP servers (simple path — uses `simple_lsp`) |
| `lsp_overrides` | `table` | Per-server extra opts for the `servers` path |
| `lsp_setup` | `function(cap)` | Full LSP config function (complex path) |
| `formatters` | `table` | Conform `formatters_by_ft` entries |
| `extra_specs` | `spec[]` | Raw lazy.nvim plugin specs (e.g. DAP) |

**Two strategies:**
- `servers` — use when servers need only `capabilities` (see `python.lua`, `node.lua`).
- `lsp_setup` — use when servers need `init_options`, `filetypes`, or custom `on_init`
  callbacks (see `vue.lua`, `dotnet.lua`).

## Adding a New Language

1. Create `lua/custom/profiles/mylang.lua`:

```lua
-- lua/custom/profiles/mylang.lua
return {
  treesitter = { 'mylang' },
  mason      = { 'mylang-lsp', 'mylang-fmt' },
  servers    = { 'mylang_ls' },
  formatters = { mylang = { 'mylang-fmt' } },
}
```

2. Add a shell alias in `~/.zshrc`:

```bash
alias nvim-mylang='NVIM_PROFILE=mylang nvim'
```

3. Launch nvim — Mason auto-installs tools; Treesitter installs parsers on first FileType match.

Use `lsp_setup` instead of `servers` if the server requires non-default `init_options` or
custom callbacks. See `lua/custom/profiles/vue.lua` for a worked example.

## Per-Project Overrides (`.nvim.lua`)

Place `.nvim.lua` in the project root. Neovim auto-loads it via `exrc` and prompts to trust
on first open.

Use `custom.terminal` helpers for project-specific keymaps:

```lua
-- .nvim.lua
local term = require("custom.terminal")

-- Runs in background; sends a notification on completion
term.bg_job("docker compose up -d", "starting dev stack")

-- Opens a floating terminal window (auto-closes on exit)
term.float_term("docker compose logs -f api")
```

Tip: bind project-specific Docker commands to `<leader>D*` overrides to complement the
always-on Docker integration (e.g. a commerce project with `vue,dotnet` and custom compose
targets).

## Key Architectural Notes

- Profiles are additive — `NVIM_PROFILE=vue,dotnet` merges Treesitter parsers, Mason tools,
  LSP servers, and extra specs (DAP) from both profiles into a single lazy.nvim load.
- `simple_lsp` configures a list of servers with shared capabilities; add `lsp_overrides`
  for per-server extras without writing a full `lsp_setup` function.
- Docker LSP (`dockerls`, `docker_compose_language_service`) and Treesitter (`dockerfile`,
  `yaml`) are always-on — they are not behind a profile flag.
- `lua_ls` is always enabled regardless of profile; it is hardcoded in the profile loader
  at `lua/custom/plugins/init.lua:98`.
