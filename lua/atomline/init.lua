local M = {}

-- 1. 總入口：把所有功能串起來
function M.setup()
  M.apply_syntax()
  
  local set = vim.opt_local
  set.expandtab = true
  set.shiftwidth = 2
  set.commentstring = "# %s"
  set.foldmethod = "expr"
  set.foldexpr = "v:lua.require'atomline'.fold_expr(v:lnum)"
  set.foldlevel = 99

  local opts = { buffer = true, silent = true }
  vim.keymap.set('n', '<leader>x', M.toggle_status, { buffer = true, desc = "Toggle Status" })
  vim.keymap.set('n', '<leader>ts', M.insert_timestamp, { buffer = true, desc = "Timestamp" })
  vim.keymap.set('i', '<CR>', M.smart_newline, { buffer = true, expr = true })
  vim.keymap.set('n', 'za', 'za', opts)
end

-- 2. 視覺邏輯
function M.apply_syntax()
  vim.cmd([[syntax on]])
  local hl = vim.api.nvim_set_hl
  hl(0, "AtomLineTodo", { fg = "#FF5555", bold = true })
  hl(0, "AtomLineDoing", { fg = "#F1FA8C", bold = true })
  hl(0, "AtomLineDone", { fg = "#50FA7B" })
  hl(0, "AtomLineContinuation", { fg = "#6272a4" })
  -- ... (其餘 hl 定義請維持原樣) ...

  vim.cmd([[
    syntax match AtomLineTodo "\[\.\]"
    syntax match AtomLineDoing "\[/\]"
    syntax match AtomLineDone "\[x\]"
    syntax match AtomLineContinuation "^\.\..*$"
    -- ... (其餘 syntax match 請維持原樣) ...
  ]])
end

-- ... (toggle_status, fold_expr, smart_newline 等其餘函數維持原樣) ...

return M
