-- Profile switcher: reads NVIM_PROFILE (comma-separated) and composes profiles.
--
-- Each profile file in lua/custom/profiles/ returns a data table:
--   treesitter  = { 'filetype', ... }
--   mason       = { 'tool', ... }
--   servers     = { 'server_name', ... }   (simple: just capabilities, no custom config)
--   lsp_overrides = { server = { extra opts } }   (optional per-server overrides for servers)
--   lsp_setup   = function(cap) → configure servers, return { 'server_name', ... }  (complex)
--   formatters  = { filetype = { 'formatter' }, ... }   (conform formatters_by_ft)
--   extra_specs = { ... }   raw Lazy plugin specs (DAP, etc.)
--
-- Usage in .zshrc:
--   alias nvim-vue='NVIM_PROFILE=vue,dotnet nvim'
--   alias nvim-react='NVIM_PROFILE=react,dotnet nvim'

-- Configure a list of LSP servers with shared capabilities + optional per-server overrides.
-- Used by simple profiles (python, node, react); complex profiles write their own lsp_setup.
local function simple_lsp(servers, cap, overrides)
  overrides = overrides or {}
  local names = {}
  for _, s in ipairs(servers) do
    vim.lsp.config(s, vim.tbl_deep_extend('force', { capabilities = cap }, overrides[s] or {}))
    names[#names + 1] = s
  end
  return names
end

local BASE_FTS = {
  'bash', 'c', 'diff', 'html',
  'lua', 'luadoc', 'markdown', 'markdown_inline',
  'query', 'vim', 'vimdoc',
}

local function dedupe(list)
  local seen, out = {}, {}
  for _, v in ipairs(list) do
    if not seen[v] then
      seen[v] = true
      table.insert(out, v)
    end
  end
  return out
end

local function build_specs(raw)
  local fts       = vim.list_extend({}, BASE_FTS)
  local tools     = {}
  local setups    = {}
  local formatters = {}
  local extra     = {}

  for name in raw:gmatch '[^,]+' do
    name = vim.trim(name)
    local ok, p = pcall(require, 'custom.profiles.' .. name)
    if not ok then
      vim.notify('NVIM_PROFILE: unknown profile "' .. name .. '"', vim.log.levels.WARN)
    else
      vim.list_extend(fts,   p.treesitter or {})
      vim.list_extend(tools, p.mason or {})
      if p.servers then
        local svrs, ovrs = p.servers, p.lsp_overrides
        table.insert(setups, function(cap) return simple_lsp(svrs, cap, ovrs) end)
      elseif p.lsp_setup then
        table.insert(setups, p.lsp_setup)
      end
      if p.formatters then formatters = vim.tbl_extend('force', formatters, p.formatters) end
      for _, s in ipairs(p.extra_specs or {}) do table.insert(extra, s) end
    end
  end

  fts   = dedupe(fts)
  tools = dedupe(tools)

  local specs = {
    -- Treesitter: single merged config
    {
      'nvim-treesitter/nvim-treesitter',
      config = function()
        require('nvim-treesitter').install(fts)
        vim.api.nvim_create_autocmd('FileType', {
          pattern  = fts,
          callback = function() pcall(vim.treesitter.start) end,
        })
      end,
    },

    -- Mason: single merged ensure_installed list
    {
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      opts = { ensure_installed = tools },
    },

    -- LSP: run each profile's setup in order, then enable all servers
    {
      'neovim/nvim-lspconfig',
      config = function()
        local cap     = require('blink.cmp').get_lsp_capabilities()
        local servers = { 'lua_ls' }
        for _, setup in ipairs(setups) do
          local added = setup(cap)
          if added then vim.list_extend(servers, added) end
        end
        vim.lsp.enable(servers)
      end,
    },

    -- Conform: merged formatters_by_ft
    {
      'stevearc/conform.nvim',
      opts = { formatters_by_ft = formatters },
    },
  }

  vim.schedule(function()
    vim.notify('Profiles: ' .. raw, vim.log.levels.INFO, { title = 'nvim' })
  end)

  vim.list_extend(specs, extra)
  return specs
end

local raw = vim.env.NVIM_PROFILE or ''
if raw == '' then return {} end
return build_specs(raw)
