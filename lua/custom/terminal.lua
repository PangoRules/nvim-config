local M = {}

function M.float_term(cmd)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.92)
  local height = math.floor(vim.o.lines * 0.88)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
  })
  vim.fn.termopen(cmd, {
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
      if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
    end,
  })
  vim.cmd 'startinsert'
end

function M.bg_job(cmd, label)
  vim.notify('Docker: ' .. label .. '…', vim.log.levels.INFO)
  vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      if code == 0 then
        vim.notify('Docker: ' .. label .. ' done', vim.log.levels.INFO)
      else
        vim.notify('Docker: ' .. label .. ' failed (exit ' .. code .. ')', vim.log.levels.WARN)
      end
    end,
  })
end

return M
