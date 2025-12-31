local M = {}

function M.setup()
  -- 執行高亮 (內含強制刷新邏輯)
  M.apply_syntax()

  -- 設定 Buffer 局部選項
  local set = vim.opt_local
  set.expandtab = true
  set.shiftwidth = 2
  set.softtabstop = 2
  set.commentstring = "# %s"
  set.foldmethod = "expr"
  set.foldexpr = "v:lua.require'atomline'.fold_expr(v:lnum)"
  set.foldlevel = 99

  -- 綁定快捷鍵
  local opts = { buffer = true, silent = true }
  vim.keymap.set('n', '<leader>x', M.toggle_status, { buffer = true, desc = "AtomLine: Toggle Status" })
  vim.keymap.set('n', '<leader>ts', M.insert_timestamp, { buffer = true, desc = "AtomLine: Timestamp" })
  vim.keymap.set('i', '<CR>', M.smart_newline, { buffer = true, expr = true })
  vim.keymap.set('n', 'za', 'za', opts)
end

-- [篩選未完成任務] 使用 Quickfix List
function M.filter_unfinished()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local qf_list = {}
  local bufnr = vim.api.nvim_get_current_buf()

  for i, line in ipairs(lines) do
    -- 搜尋包含 [.] 或 [/] 的行
    if line:find("%[%.%]") or line:find("%[/%]") then
      table.insert(qf_list, {
        bufnr = bufnr,
        lnum = i,
        text = line:gsub("^%s+", ""), -- 去除行首空格讓清單更整齊
      })
    end
  end

  if #qf_list > 0 then
    vim.fn.setqflist(qf_list)
    vim.cmd("copen") -- 開啟 Quickfix 視窗
    print("Found " .. #qf_list .. " unfinished tasks.")
  else
    print("All tasks completed! Good job.")
  end
end

function M.apply_syntax()
  -- 強制啟動語法引擎，解決啟動時黑白的問題
  vim.cmd([[
    syntax enable
    if !exists("g:syntax_on")
      syntax on
    endif
  ]])

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

  -- 注入語法規則
  vim.cmd([[
    syntax clear
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

-- 功能：狀態切換
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

-- 功能：摺疊
function M.fold_expr(lnum)
  local line = vim.fn.getline(lnum)
  if line:match("^%.%.") or line:match("^#") then return "1" end
  return "0"
end

-- 功能：智慧續行
function M.smart_newline()
  local line = vim.api.nvim_get_current_line()
  if line:find("^%[") or line:find("^%.%.") then
    return vim.api.nvim_replace_termcodes("<CR>.. ", true, false, true)
  else
    return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  end
end

-- 功能：時間戳記
function M.insert_timestamp()
  local timestamp = os.date("%Y-%m-%d %H:%M %a | ")
  vim.api.nvim_put({timestamp}, "c", true, true)
end

return M
