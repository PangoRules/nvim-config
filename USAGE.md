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
    │   ├── dotnet.lua
    │   └── rest.lua
    └── terminal.lua           # float_term / bg_job helpers
```

## Shell Setup

Set `NVIM_PROFILE` to a comma-separated list of profile names:

```bash
# ~/.zshrc
alias nvim-vue='NVIM_PROFILE=vue,dotnet nvim'               # Vue + .NET (Hybrid Mode)
alias nvim-react='NVIM_PROFILE=react nvim'
alias nvim-react-dotnet='NVIM_PROFILE=react,dotnet nvim'    # React + .NET
alias nvim-python='NVIM_PROFILE=python nvim'
alias nvim-node='NVIM_PROFILE=node nvim'
alias nvim-dotnet='NVIM_PROFILE=dotnet nvim'
alias nvim-nuxt-dotnet-py='NVIM_PROFILE=vue,dotnet,python,rest nvim'  # Nuxt + .NET + Python + REST
```

Profiles are additive — `vue,dotnet` merges both stacks including DAP.

**Per-project auto-activation:** place a `.nvim-profile` file in the project root containing
the profile string (e.g. `vue,dotnet,python,rest`). `init.lua` reads it at startup when
`NVIM_PROFILE` is not already set in the environment — so the explicit alias always wins.
The file is in the global gitignore; commit it intentionally if your team should share it.

**Per-session overrides:** place a `.nvim.lua` in the project root for Lua-level config
(keymaps, vim options, plugin globals). Auto-loaded via `exrc` (Neovim 0.9+). Nvim prompts
to trust on first open (`:trust` while the file is the current buffer).

Example use — pin a Roslyn solution file per project:

```lua
-- .nvim.lua
vim.g.roslyn_nvim_selected_solution = vim.fn.getcwd() .. '/src/MyApp/MyApp.sln'
```

## Always-On Plugins

| Plugin | Purpose | Key binding(s) |
|--------|---------|----------------|
| Telescope | Fuzzy finder: files, grep, LSP, help | `<leader>s*`, `<leader>/`, `<leader><leader>` |
| Oil.nvim | File explorer as editable buffer | `-` |
| Harpoon | File bookmarks & quick jump (per-tab) | `<leader>h*` |
| Grug-far | Project-wide find & replace | `<leader>sr` |
| refactoring.nvim | Treesitter/LSP-powered refactors | `<leader>r*` |
| Trouble | Diagnostics / todo panel | `<leader>x*` |
| Neogit | Git commit / branch / push / pull workflow | `<leader>g*` |
| Diffview | Git diff, file history, repo log | `<leader>gd`, `<leader>gD`, `<leader>gh`, `<leader>gl` |
| Gitsigns | Git gutter signs (+/~/_ markers) | — |
| vim-dadbod-ui | Database explorer (SQL Server, PostgreSQL, MySQL, …) | `<leader>Q*` |
| persistence.nvim | Session save/restore with tab workspace support | `<leader>S*` |
| Render Markdown | In-buffer rendering of headers, tables, checkboxes | automatic on `.md` files |
| nvim-ufo | LSP/indent-based folding with peek preview | `zR`, `zM`, `zK` |
| Autopairs | Auto-close brackets/quotes (TS-aware) | — (InsertEnter) |
| Conform | Format buffer (also on save) | `<leader>f` |
| Blink.cmp | LSP completion | `<c-y>` accept, `<c-n/p>`, `<c-space>`, `<c-e>`, `<c-k>` |
| Which-key | Pending keymap overlay | — (automatic) |
| Todo-comments | Highlight `TODO/FIXME/NOTE` in code | surfaces via `<leader>xt` |
| Mini.ai | Extended text objects | `va)`, `ci'`, `yinq` |
| Mini.surround | Add/delete/replace surroundings | `sa`, `sd`, `sr` |
| nvim-lspconfig | LSP client (`lua_ls` always on) | `grn`, `gra`, `grr`, `grd`, `gri`, `grt`, `grD`, `gO`, `gW` |
| Docker integration | Dockerfile/compose LSP + keymaps | `<leader>D*` |
| sql-formatter | SQL formatting via conform | automatic on `.sql` files via `<leader>f` |

## Tab Workspace System

Tabs can be named. The tabline shows tab number + name (or number only if unnamed).

```
:TabRename docs          " name current tab "docs"
:TabRename front         " name current tab "front"
:TabRename back          " name current tab "back"
:TabRename dbui          " name current tab "dbui"
```

**Harpoon is per-tab** — each named tab has its own bookmark list. Switch tabs and your
harpoon marks switch with you. Unnamed tabs share a default list.

**Tab navigation:** use standard Neovim tab commands (`gt`, `gT`, `<number>gt`) or
`:tabnew`, `:tabclose`.

## Session Persistence

Sessions remember: open buffers, window layout, tab pages, tab names, Oil paths per tab,
DBUI tab state, and terminal working directories.

**On startup** (when launched with no file args): prompted to restore the last session.

**On exit** (`:q`, `:qa`, etc.): prompted to save the current session before closing.
Choose `No` to exit without overwriting the saved session.

| Keymap | Description |
|--------|-------------|
| `<leader>Ss` | Save session now |
| `<leader>Sl` | Load session for current directory |
| `<leader>SL` | Select from all sessions (picker) |
| `<leader>Sd` | Stop session tracking (exit won't save) |
| `<leader>SD` | Delete a session (picker) |

Sessions are stored per-directory in `~/.local/share/nvim/sessions/`.

## Keymap Reference

### Core / Window Navigation

| Keymap | Mode | Description |
|--------|------|-------------|
| `<C-h/j/k/l>` | n | Move focus between windows |
| `<Esc>` | n | Clear search highlights |
| `<Esc><Esc>` | t | Exit terminal mode |
| `<leader>q` | n | Open diagnostic quickfix list |
| `<leader>th` | n | Toggle inlay hints (LSP, when server supports it) |

### Terminal

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>ts` | n | Open terminal split below (15 lines) |
| `<leader>tt` | n | Open terminal in new tab |
| `<Esc><Esc>` | t | Exit terminal insert mode (back to normal) |

### Telescope

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader><leader>` | n | Find open buffers |
| `<leader>sb` | n | Search open buffers |
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

Harpoon lists are scoped per tab name. Each named tab has independent bookmarks.

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

### Refactoring

Refactors are most reliable when the matching `NVIM_PROFILE` is active so the right
Treesitter parser and LSP are loaded for the current language.

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>rr` | n/v | Select available refactor for current cursor / selection |
| `<leader>re` | n/v | Extract function |
| `<leader>rE` | n/v | Extract function to file |
| `<leader>rb` | n/v | Extract block |
| `<leader>rV` | n/v | Extract variable |
| `<leader>ri` | n/v | Inline variable |
| `<leader>rI` | n/v | Inline function |
| `<leader>rv` | n/v | Debug print variable below with location |
| `<leader>rc` | n/v | Cleanup refactoring.nvim debug prints |

In visual mode, select code first and then trigger the mapping. In normal mode, the
direct refactor mappings are operator-style: trigger the mapping, then give a textobject
or motion. Example: `<leader>rViw` extracts the word under cursor as a variable.

`<leader>rv` uses refactoring.nvim's debug printer, so the inserted statement includes the
plugin's debug marker and can be removed later with `<leader>rc`.

### Git

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>gg` | n | Open Neogit |
| `<leader>gc` | n | Git commit |
| `<leader>gp` | n | Git push |
| `<leader>gP` | n | Git pull |
| `<leader>gb` | n | Git branch |
| `<leader>ga` | n | `git add -A` (stage all) |
| `<leader>gd` | n | Diff working tree (Diffview) |
| `<leader>gD` | n | Close diff view |
| `<leader>gh` | n | Current file history |
| `<leader>gl` | n | Repo log |

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

### Database

Connections are stored in `~/.local/share/nvim/db_ui/`. Add them with `<leader>Qa`.

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>Qq` | n | Open DB UI in a dedicated tab (creates one if not open) |
| `<leader>QQ` | n | Toggle DB UI sidebar (raw, wherever you are) |
| `<leader>Qa` | n | Add connection |
| `<leader>Qf` | n | Find buffer's connection |

**Saving queries:** in a DB query buffer press `W` to save the query to a named file
(stored under `~/.local/share/nvim/db_ui/`).

**Connection string formats:**

```
postgresql://user:pass@host:5432/dbname
sqlserver://user:pass@host:1433?database=dbname
mysql://user:pass@host:3306/dbname
```

### REST Client (rest profile only)

Keymaps active only inside `.http` files.

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>Rr` | n | Run request under cursor |
| `<leader>Ra` | n | Run all requests in file |
| `<leader>Rn` | n | Next request |
| `<leader>Rp` | n | Previous request |
| `<leader>Rt` | n | Toggle body / headers view |
| `<leader>Rc` | n | Copy as curl command |
| `<leader>Re` | n | Select environment |
| `<leader>Ri` | n | Inspect request (dry-run) |

Create a `.http` file alongside your API tests. Environments live in `http-client.env.json`
in the same directory as the `.http` file.

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
| `<leader>xe` | n | Show diagnostic float under cursor |

### Folding

| Keymap | Mode | Description |
|--------|------|-------------|
| `zR` | n | Open all folds |
| `zM` | n | Close all folds |
| `zK` | n | Peek inside fold under cursor |

### Debug (dotnet profile only)

| Keymap | Mode | Description |
|--------|------|-------------|
| `<F5>` | n | Start / Continue |
| `<F10>` | n | Step Over |
| `<F11>` | n | Step Into |
| `<F12>` | n | Step Out |
| `<leader>db` | n | Toggle breakpoint |
| `<leader>dB` | n | Conditional breakpoint |
| `<leader>dbc` | n | Clear all breakpoints |
| `<leader>du` | n | Toggle DAP UI |
| `<leader>dr` | n | Restart |
| `<leader>dc` | n | Run to cursor |
| `<leader>dl` | n | Run last |

#### Debug — Watch / Scope

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>dwe` | n/v | Evaluate expression under cursor / selection |
| `<leader>dwh` | n/v | Hover variable (inline float) |
| `<leader>dww` | n | Watches panel (press `a` to add, `d` to delete) |
| `<leader>dws` | n | Scopes (Locals) panel float |

#### Debug — Neotest

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>dtt` | n | Run nearest test |
| `<leader>dtf` | n | Run current file |
| `<leader>dta` | n | Run all tests |
| `<leader>dtl` | n | Run last test |
| `<leader>dtw` | n | Watch current file |
| `<leader>dtd` | n | Debug nearest test (via netcoredbg) |
| `<leader>dts` | n | Toggle test summary panel |
| `<leader>dto` | n | Open test output |
| `<leader>dtp` | n | Toggle output panel |

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
on first open. Open the file (`:e .nvim.lua`) then run `:trust` to approve it.

Use `custom.terminal` helpers for project-specific keymaps:

```lua
-- .nvim.lua
local term = require("custom.terminal")

-- Runs in background; sends a notification on completion
term.bg_job("docker compose up -d", "starting dev stack")

-- Opens a floating terminal window (auto-closes on exit)
term.float_term("docker compose logs -f api")

-- Pin the Roslyn solution file (dotnet profile)
vim.g.roslyn_nvim_selected_solution = vim.fn.getcwd() .. '/src/MyApp/MyApp.sln'
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
  at `lua/custom/plugins/init.lua`.
- Harpoon lists are keyed by the current tab's name (`vim.t.tabname`). Unnamed tabs share
  a default list named `""`.
- Sessions save `vim.g.TabData` (JSON) into `sessionoptions=globals` to persist tab names
  and per-tab state (oil path, dbui flag, terminal CWD) across restarts.
