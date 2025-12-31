local M = {}

-- 總入口：整合所有功能
function M.setup()
  -- 1. 啟動高亮
  M.apply_syntax()

  -- 2. 緩衝區設定 (Buffer-local)
  local set = vim.opt_local
  set.expandtab = true
  set.shiftwidth = 2
  set.softtabstop = 2
  set.commentstring = "# %s"
  
  -- 3. 自動摺疊設定
  set.foldmethod = "expr"
  set.foldexpr = "v:lua.require'atomline'.fold_expr(v:lnum)"
  set.foldlevel = 99

  -- 4. 快捷鍵綁定
  local opts = { buffer = true, silent = true }
  vim.keymap.set('n', '<leader>x', M.toggle_status, { buffer = true, desc = "AtomLine: Toggle Status" })
  vim.keymap.set('n', '<leader>ts', M.insert_timestamp, { buffer = true, desc = "AtomLine: Insert Timestamp" })
  vim.keymap.set('i', '<CR>', M.smart_newline, { buffer = true, expr = true })
  vim.keymap.set('n', 'za', 'za', opts)
end

-- 高亮規則定義
function M.apply_syntax()
  vim.cmd([[syntax on]])
  local hl = vim.api.nvim_set_hl
  
  -- 顏色定義
  hl(0, "AtomLineTodo",         { fg = "#FF5555", bold = true })
  hl(0, "AtomLineDoing",        { fg = "#F1FA8C", bold = true })
  hl(0, "AtomLineDone",         { fg = "#50FA7B" })
  hl(0, "AtomLineMigrate",      { fg = "#BD93F9" })
  hl(0, "AtomLineContinuation", { fg = "#6272a4" })
  hl(0, "AtomLineComment",      { fg = "#44475a", italic = true })
  hl(0, "AtomLineTag",          { fg = "#FF79C6" })
  hl(0, "AtomLinePerson",       { fg = "#8BE9FD" })
  hl(0, "AtomLinePlace",        { fg = "#FFB86C" })
  hl(0, "AtomLineDeadline",     { fg = "#FF5555", underline = true })
  hl(0, "AtomLineSeparator",    { fg = "#6272a4", italic = true })

  vim.cmd([[
    syntax match AtomLineTodo "\[\.\]"
    syntax match AtomLineDoing "\[/\]"
    syntax match AtomLineDone "\[x\]"
    syntax match AtomLineMigrate "\[>\]"
    syntax match AtomLineContinuation "^\.\..*$"
    syntax match AtomLineComment "^#.*$"
    syntax match AtomLineTag ":[^:]\+:"
    syntax match AtomLinePerson "\~[^ ]\+"
    syntax match AtomLinePlace "@[^ ]\+"
    syntax match AtomLineDeadline "![0-9-]\+"
    syntax match AtomLineSeparator "||.*$"
  ]])
end

-- 任務狀態切換 [.] -> [/] -> [x]
function M.toggle_status()
  local line = vim.api.nvim_get_current_line()
  local states = { "%[%.%]", "%[/%]", "%[x%]" }
  local next_states = { "[.]", "[/]", "[x]" }
  for i, s in ipairs(states) do
    if line:find(s) then
      local next_idx = (i % #next_states) + 1
      vim.api.nvim_set_current_line(line:gsub(s, next_states[next_idx], 1))
      return
    end
  end
end

-- 摺疊判斷 (.. 與 # 摺疊進上一行)
function M.fold_expr(lnum)
  local line = vim.fn.getline(lnum)
  if line:match("^%.%.") or line:match("^#") then return "1" end
  return "0"
end

-- 智慧續行 (Insert Mode 下按 CR)
function M.smart_newline()
  local line = vim.api.nvim_get_current_line()
  if line:find("^%[") or line:find("^%.%.") then
    return vim.api.nvim_replace_termcodes("<CR>.. ", true, false, true)
  else
    return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  end
end

-- 插入時間戳記
function M.insert_timestamp()
  local timestamp = os.date("%Y-%m-%d %H:%M %a | ")
  vim.api.nvim_put({timestamp}, "c", true, true)
end

return M
