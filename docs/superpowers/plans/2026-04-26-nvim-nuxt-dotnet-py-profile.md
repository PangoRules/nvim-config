# Nvim nuxt-dotnet-py Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reusable `nvim-nuxt-dotnet-py` profile combining Vue/Nuxt 3, ASP.NET Core, Python, and a REST client, with per-project auto-activation via a `.nvim-profile` file.

**Architecture:** New `rest.lua` profile added to `~/.config/nvim/lua/custom/profiles/`; five-line patch to `init.lua` reads `.nvim-profile` from project root before lazy.nvim loads, enabling automatic profile activation. Python profile updated in-place. Shell alias and gitignore entry added to the dotfiles repo.

**Tech Stack:** Neovim (lazy.nvim, which-key, conform), kulala.nvim (REST client), ruff (Python formatter/linter), zsh

---

## File Map

| File | Action | What changes |
|------|--------|-------------|
| `~/dotfiles/shell/.zshrc` | Modify | Add `nvim-nuxt-dotnet-py` alias |
| `~/dotfiles/git/ignore` | Modify | Add `.nvim-profile` global gitignore entry |
| `~/.config/nvim/init.lua` | Modify | Insert `.nvim-profile` auto-detection block before `require('lazy').setup(` |
| `~/.config/nvim/lua/custom/profiles/python.lua` | Modify | Replace `black` with `ruff_format`; add `toml` parser |
| `~/.config/nvim/lua/custom/profiles/rest.lua` | Create | kulala.nvim plugin spec + buffer-local `<leader>R*` keymaps |
| `~/Projects/cook-homie/.nvim-profile` | Create | Contains `vue,dotnet,python,rest` |
| `~/.config/nvim/USAGE.md` | Modify | Add alias, auto-activation docs, REST keymap table |

---

## Task 1: Add shell alias and global gitignore entry

**Files:**
- Modify: `~/dotfiles/shell/.zshrc` (after line 131)
- Modify: `~/dotfiles/git/ignore`

- [ ] **Step 1: Add alias to .zshrc**

Open `~/dotfiles/shell/.zshrc`. After the existing nvim aliases (currently ending with `alias nvim-node='NVIM_PROFILE=node nvim'`), add:

```zsh
alias nvim-nuxt-dotnet-py='NVIM_PROFILE=vue,dotnet,python,rest nvim'
```

The block should now read:

```zsh
alias nvim-vue='NVIM_PROFILE=vue,dotnet nvim'
alias nvim-react='NVIM_PROFILE=react nvim'
alias nvim-react-dotnet='NVIM_PROFILE=react,dotnet nvim'
alias nvim-python='NVIM_PROFILE=python nvim'
alias nvim-node='NVIM_PROFILE=node nvim'
alias nvim-nuxt-dotnet-py='NVIM_PROFILE=vue,dotnet,python,rest nvim'
```

- [ ] **Step 2: Add .nvim-profile to global gitignore**

Open `~/dotfiles/git/ignore`. Add a new line:

```
.nvim-profile
```

The file should now contain:

```
**/.claude/settings.local.json
.nvim-profile
```

- [ ] **Step 3: Reload shell and verify alias**

```bash
source ~/.zshrc
alias | grep nvim-nuxt-dotnet-py
```

Expected output:
```
nvim-nuxt-dotnet-py='NVIM_PROFILE=vue,dotnet,python,rest nvim'
```

- [ ] **Step 4: Commit dotfiles**

```bash
cd ~/dotfiles
git add shell/.zshrc git/ignore
git commit -m "feat: add nvim-nuxt-dotnet-py alias and .nvim-profile gitignore"
```

---

## Task 2: Auto-detection patch in init.lua

**Files:**
- Modify: `~/.config/nvim/init.lua` (insert before the `require('lazy').setup({` call at line 263)

- [ ] **Step 1: Insert auto-detection block**

In `~/.config/nvim/init.lua`, find this line (currently line 263):

```lua
require('lazy').setup({
```

Insert the following block **immediately before** it (keep the comment above it intact):

```lua
-- Auto-load NVIM_PROFILE from a .nvim-profile file in the project tree.
-- Walks up from cwd so it works from any subdirectory. Only fires when
-- NVIM_PROFILE is not already set (explicit env var / alias always wins).
if (vim.env.NVIM_PROFILE or '') == '' then
  local f = vim.fn.findfile('.nvim-profile', '.;')
  if f ~= '' then
    vim.env.NVIM_PROFILE = vim.trim(vim.fn.readfile(f)[1] or '')
  end
end

-- NOTE: Here is where you install your plugins.
require('lazy').setup({
```

(Remove the original `-- NOTE: Here is where you install your plugins.` line above `require('lazy')` since you're including it in the replacement block.)

- [ ] **Step 2: Verify nvim starts without errors**

```bash
cd /tmp && nvim --headless +qa 2>&1
```

Expected: no output (silent clean exit). Any Lua error prints to stderr.

- [ ] **Step 3: Verify NVIM_PROFILE env var is NOT set globally (sanity check)**

```bash
echo "NVIM_PROFILE=${NVIM_PROFILE:-<unset>}"
```

Expected: `NVIM_PROFILE=<unset>` — confirms the auto-detection only fires inside nvim, not the shell.

- [ ] **Step 4: Commit nvim config**

```bash
cd ~/.config/nvim
git add init.lua
git commit -m "feat: auto-load NVIM_PROFILE from .nvim-profile file in project tree"
```

---

## Task 3: Improve python.lua (ruff format + toml treesitter)

**Files:**
- Modify: `~/.config/nvim/lua/custom/profiles/python.lua`

- [ ] **Step 1: Replace python.lua contents**

Replace the entire file with:

```lua
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
```

- [ ] **Step 2: Verify Mason uninstalls black (optional but clean)**

Launch nvim with the python profile:

```bash
NVIM_PROFILE=python nvim
```

Run `:Mason` — `black` should no longer appear in the auto-installed tools list. If it was previously installed, it won't be removed automatically (Mason doesn't uninstall unused tools). To remove manually: `:MasonUninstall black`.

- [ ] **Step 3: Verify ruff formatter is available**

Still inside nvim with python profile, run:

```
:ConformInfo
```

Expected: `ruff_fix` and `ruff_format` listed as formatters for `python` filetype.

- [ ] **Step 4: Verify TOML syntax highlighting**

Create a quick test file:

```bash
NVIM_PROFILE=python nvim /tmp/test.toml
```

Type `[section]` and `key = "value"` — confirm Treesitter highlighting applies (section headers and keys render in distinct colours).

- [ ] **Step 5: Commit**

```bash
cd ~/.config/nvim
git add lua/custom/profiles/python.lua
git commit -m "feat(python): replace black with ruff_format, add toml treesitter parser"
```

---

## Task 4: Create rest.lua profile (kulala.nvim + REST keymaps)

**Files:**
- Create: `~/.config/nvim/lua/custom/profiles/rest.lua`

- [ ] **Step 1: Create rest.lua**

Create `~/.config/nvim/lua/custom/profiles/rest.lua` with these contents:

```lua
-- REST client profile: kulala.nvim for .http file execution
return {
  treesitter = { 'http', 'json' },

  mason = {},

  extra_specs = {
    {
      'mistweaverco/kulala.nvim',
      ft = 'http',
      opts = {
        default_view = 'body',
        default_env  = 'dev',
      },
      config = function(_, opts)
        local kulala = require 'kulala'
        kulala.setup(opts)

        local k = vim.keymap.set

        vim.api.nvim_create_autocmd('FileType', {
          pattern  = 'http',
          callback = function()
            require('which-key').add { { '<leader>R', group = '[R]EST', buffer = true } }
            k('n', '<leader>Rr', kulala.run,             { buffer = true, desc = 'REST: Run request' })
            k('n', '<leader>Ra', kulala.run_all,          { buffer = true, desc = 'REST: Run all' })
            k('n', '<leader>Rn', kulala.jump_next,        { buffer = true, desc = 'REST: Next request' })
            k('n', '<leader>Rp', kulala.jump_prev,        { buffer = true, desc = 'REST: Previous request' })
            k('n', '<leader>Rt', kulala.toggle_view,      { buffer = true, desc = 'REST: Toggle body/headers' })
            k('n', '<leader>Rc', kulala.copy_as_curl,     { buffer = true, desc = 'REST: Copy as curl' })
            k('n', '<leader>Re', kulala.set_selected_env, { buffer = true, desc = 'REST: Select environment' })
            k('n', '<leader>Ri', kulala.inspect,          { buffer = true, desc = 'REST: Inspect request' })
          end,
        })
      end,
    },
  },
}
```

- [ ] **Step 2: Verify profile loads without errors**

```bash
NVIM_PROFILE=rest nvim --headless +qa 2>&1
```

Expected: no output.

- [ ] **Step 3: Create a test .http file and verify kulala loads**

```bash
NVIM_PROFILE=rest nvim /tmp/test.http
```

Inside nvim, type this request:

```http
GET https://httpbin.org/get
```

Run `:checkhealth kulala` — expected: all checks pass (or only optional warnings).

- [ ] **Step 4: Verify which-key shows the REST group**

With `/tmp/test.http` open, press `<Space>R` — which-key should show the `[R]EST` group with all 8 bindings listed.

- [ ] **Step 5: Send a request**

With the cursor on the `GET` line, press `<leader>Rr`. Expected: a response pane opens showing the JSON response from httpbin.

- [ ] **Step 6: Verify `<leader>Rt` toggles to headers view**

Press `<leader>Rt` — the response pane should switch to show response headers (`Content-Type`, `Date`, etc.).

- [ ] **Step 7: Commit**

```bash
cd ~/.config/nvim
git add lua/custom/profiles/rest.lua
git commit -m "feat: add rest profile with kulala.nvim and leader-R keymaps"
```

---

## Task 5: Create .nvim-profile in cook-homie and verify end-to-end

**Files:**
- Create: `~/Projects/cook-homie/.nvim-profile`

- [ ] **Step 1: Create .nvim-profile**

```bash
echo 'vue,dotnet,python,rest' > ~/Projects/cook-homie/.nvim-profile
```

- [ ] **Step 2: Verify end-to-end auto-detection from a subdirectory**

```bash
cd ~/Projects/cook-homie/src/CookHomie.Web
nvim --headless +"lua print(vim.env.NVIM_PROFILE)" +qa 2>&1
```

Expected output:
```
vue,dotnet,python,rest
```

- [ ] **Step 3: Verify all LSPs attach on correct filetypes**

```bash
cd ~/Projects/cook-homie
nvim src/CookHomie.Web/pages/index.vue
```

Inside nvim, run `:LspInfo` — expected: `ts_ls` and `vue_ls` both listed as active clients for the `.vue` buffer.

```bash
nvim src/CookHomie.Api/CookHomie.SpikeApi/Program.cs
```

Run `:LspInfo` — expected: `roslyn` listed as active.

```bash
nvim src/CookHomie.MCP/server.py
```

Run `:LspInfo` — expected: `pyright` listed as active.

- [ ] **Step 4: Verify NVIM_PROFILE outside project is still empty**

```bash
cd /tmp
nvim --headless +"lua print('profile=' .. (vim.env.NVIM_PROFILE or ''))" +qa 2>&1
```

Expected output:
```
profile=
```

- [ ] **Step 5: Verify explicit alias still overrides .nvim-profile**

```bash
cd ~/Projects/cook-homie
NVIM_PROFILE=python nvim --headless +"lua print(vim.env.NVIM_PROFILE)" +qa 2>&1
```

Expected output:
```
python
```

(Explicit env var wins; `.nvim-profile` is ignored.)

- [ ] **Step 6: Commit .nvim-profile to cook-homie**

```bash
cd ~/Projects/cook-homie
git add .nvim-profile
git commit -m "chore: add .nvim-profile for nvim auto-activation (vue,dotnet,python,rest)"
```

---

## Task 6: Update USAGE.md

**Files:**
- Modify: `~/.config/nvim/USAGE.md`

- [ ] **Step 1: Add new alias to Shell Setup section**

Find the alias block in the `## Shell Setup` section (currently ends with `alias nvim-dotnet`). Add the new alias and a note about auto-activation:

The section should become:

```markdown
## Shell Setup

Set `NVIM_PROFILE` to a comma-separated list of profile names:

```bash
# ~/.zshrc
alias nvim-python='NVIM_PROFILE=python nvim'
alias nvim-node='NVIM_PROFILE=node nvim'
alias nvim-react='NVIM_PROFILE=react nvim'
alias nvim-vue='NVIM_PROFILE=vue,dotnet nvim'          # combine stacks
alias nvim-dotnet='NVIM_PROFILE=dotnet nvim'
alias nvim-nuxt-dotnet-py='NVIM_PROFILE=vue,dotnet,python,rest nvim'  # Nuxt + .NET + Python + REST
```

Profiles are additive — `vue,dotnet` merges both stacks including DAP.

**Per-project auto-activation:** place a `.nvim-profile` file in the project root containing
the profile string (e.g. `vue,dotnet,python,rest`). `init.lua` reads it at startup when
`NVIM_PROFILE` is not already set in the environment — so the explicit alias always wins.
The file is in the global gitignore; commit it intentionally if your team should share it.

**Per-session overrides:** place a `.nvim.lua` in the project root for Lua-level config
(keymaps, vim options). Auto-loaded via `exrc` (Neovim 0.9+). Nvim prompts to trust on first open.
```

- [ ] **Step 2: Add REST keymap section after the Database section**

Find `### Database` and the block that follows it. After the database connection format block, add a new `### REST Client` section:

```markdown
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
```

- [ ] **Step 3: Add rest.lua to the directory layout**

Find the directory layout block:

```
    ├── profiles/              # One file per language stack
    │   ├── python.lua
    │   ├── node.lua
    │   ├── react.lua
    │   ├── vue.lua
    │   └── dotnet.lua
```

Update it to include `rest.lua`:

```
    ├── profiles/              # One file per language stack
    │   ├── python.lua
    │   ├── node.lua
    │   ├── react.lua
    │   ├── vue.lua
    │   ├── dotnet.lua
    │   └── rest.lua
```

- [ ] **Step 4: Commit USAGE.md**

```bash
cd ~/.config/nvim
git add USAGE.md
git commit -m "docs: update USAGE.md for nuxt-dotnet-py profile, .nvim-profile, REST keymaps"
```
