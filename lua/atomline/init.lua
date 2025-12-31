local M = {}

-- =============================================================================
-- 1. 總入口 (Setup)
-- =============================================================================
function M.setup()
  M.apply_syntax()

  local set = vim.opt_local
  set.expandtab = true
  set.shiftwidth = 2
  set.softtabstop = 2
  set.commentstring = "# %s"
  set.foldmethod = "expr"
  set.foldexpr = "v:lua.require'atomline'.fold_expr(v:lnum)"
  set.foldlevel = 99

  local opts = { buffer = true, silent = true }
  
  -- 快捷鍵綁定
  vim.keymap.set('n', '<leader>x', M.toggle_status, { buffer = true, desc = "AtomLine: Cycle Status" })
  vim.keymap.set('n', '<leader>ts', M.insert_timestamp, { buffer = true, desc = "AtomLine: Timestamp" })
  vim.keymap.set('i', '<CR>', M.smart_newline, { buffer = true, expr = true })
  vim.keymap.set('n', '<leader>f', M.filter_unfinished, { buffer = true, desc = "AtomLine: Filter" })
  vim.keymap.set('n', 'za', 'za', opts)
end

-- =============================================================================
-- 2. 視覺高亮 (新增 AtomLineTimeRange)
-- =============================================================================
function M.apply_syntax()
  vim.cmd([[
    syntax enable
    if !exists("g:syntax_on") | syntax on | endif
  ]])
  
  local hl = vim.api.nvim_set_hl
  
  -- 任務與活動狀態
  hl(0, "AtomLineTodo",         { fg = "#FF5555", bold = true }) -- [.]
  hl(0, "AtomLineDoing",        { fg = "#F1FA8C", bold = true }) -- [/]
  hl(0, "AtomLineActive",       { fg = "#8BE9FD", bold = true }) -- [-]
  hl(0, "AtomLineDone",         { fg = "#50FA7B" })              -- [x]
  hl(0, "AtomLineCompleted",    { fg = "#50FA7B", bold = true }) -- [+]
  hl(0, "AtomLineMigrate",      { fg = "#BD93F9" })              -- [>]
  
  -- 結構與備註
  hl(0, "AtomLineContinuation", { fg = "#6272a4" })              -- ..
  hl(0, "AtomLineComment",      { fg = "#44475a", italic = true }) -- #
  hl(0, "AtomLineSeparator",    { fg = "#6272a4", italic = false }) -- |
  
  -- 時間與區間 (皆為正體)
  hl(0, "AtomLineTime",         { fg = "#8BE9FD", italic = false })
  -- [更名] 時間區間：橘色粗體
  hl(0, "AtomLineTimeRange",    { fg = "#FFB86C", bold = true })

  -- 內容標記
  hl(0, "AtomLineTag",          { fg = "#FF79C6" })              -- :tag:
  hl(0, "AtomLinePerson",       { fg = "#8BE9FD" })              -- ~person
  hl(0, "AtomLinePlace",        { fg = "#FFB86C" })              -- @place
  hl(0, "AtomLineDeadline",     { fg = "#FF5555", underline = true })

  vim.cmd([[
    syntax clear
    " 1. 狀態匹配
    syntax match AtomLineTodo "\[\.\]"
    syntax match AtomLineDoing "\[/\]"
    syntax match AtomLineActive "\[-\]"
    syntax match AtomLineDone "\[x\]"
    syntax match AtomLineCompleted "\[+\]"
    syntax match AtomLineMigrate "\[>\]"
    
    " 2. 結構匹配
    syntax match AtomLineContinuation "^\.\..*$"
    syntax match AtomLineComment "^#.*$"
    
    " 3. [重點] 時間區間：YYYY-MM-DD/YYYY-MM-DD
    syntax match AtomLineTimeRange "[0-9-]\{10}/[0-9-]\{10}"
    
    " 4. 時間戳記與分隔符
    syntax match AtomLineTime "[0-9-]\{10} [0-9:]\{5} [A-Za-z]\{3}"
    syntax match AtomLineSeparator "[|]\{1,2}"
    
    " 5. 其他標記
    syntax match AtomLineTag ":[^:]\+:"
    syntax match AtomLinePerson "\~[^ ]\+"
    syntax match AtomLinePlace "@[^ ]\+"
    syntax match AtomLineDeadline "![0-9-]\+"
  ]])
end

-- =============================================================================
-- 3. 核心功能
-- =============================================================================

-- 分組循環：(1) [.]->[/]->[x]  (2) [-]->[+]
function M.toggle_status()
  local line = vim.api.nvim_get_current_line()
  local g1_states, g1_next = { "%[%.%]", "%[/%]", "%[x%]" }, { "[.]", "[/]", "[x]" }
  local g2_states, g2_next = { "%[%-%]", "%[%+%]" }, { "[-]", "[+]" }

  for i, s in ipairs(g1_states) do
    if line:find(s) then
      vim.api.nvim_set_current_line(line:gsub(s, g1_next[(i % #g1_next) + 1], 1))
      return
    end
  end

  for i, s in ipairs(g2_states) do
    if line:find(s) then
      vim.api.nvim_set_current_line(line:gsub(s, g2_next[(i % #g2_next) + 1], 1))
      return
    end
  end
end

-- 快速篩選 (Quickfix)
function M.filter_unfinished()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local qf_list, bufnr = {}, vim.api.nvim_get_current_buf()
  for i, line in ipairs(lines) do
    if line:find("%[%.%]") or line:find("%[/%]") or line:find("%[%-%]") then
      table.insert(qf_list, { bufnr = bufnr, lnum = i, text = line:gsub("^%s+", "") })
    end
  end
  if #qf_list > 0 then
    vim.fn.setqflist(qf_list)
    vim.cmd("copen")
  else
    print("All tasks and activities are complete.")
  end
end

-- 自動摺疊
function M.fold_expr(lnum)
  local line = vim.fn.getline(lnum)
  return (line:match("^%.%.") or line:match("^#")) and "1" or "0"
end

-- 智慧續行
function M.smart_newline()
  local line = vim.api.nvim_get_current_line()
  if line:find("^%[") or line:find("^%.%.") then
    return vim.api.nvim_replace_termcodes("<CR>.. ", true, false, true)
  end
  return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
end

-- 插入時間戳記
function M.insert_timestamp()
  local timestamp = os.date("%
