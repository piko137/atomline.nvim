local M = {}

-- =============================================================================
-- 1. 總入口
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
-- 2. 視覺高亮 (保持不變)
-- =============================================================================
function M.apply_syntax()
  vim.cmd([[
    syntax enable
    if !exists("g:syntax_on") | syntax on | endif
  ]])
  
  local hl = vim.api.nvim_set_hl
  
  -- 顏色設定
  hl(0, "AtomLineTodo",         { fg = "#FF5555", bold = true }) -- [.]
  hl(0, "AtomLineDoing",        { fg = "#F1FA8C", bold = true }) -- [/]
  hl(0, "AtomLineActive",       { fg = "#8BE9FD", bold = true }) -- [-]
  hl(0, "AtomLineDone",         { fg = "#50FA7B" })              -- [x]
  hl(0, "AtomLineCompleted",    { fg = "#50FA7B", bold = true }) -- [+]
  
  hl(0, "AtomLineMigrate",      { fg = "#BD93F9" })              -- [>]
  hl(0, "AtomLineContinuation", { fg = "#6272a4" })              -- ..
  hl(0, "AtomLineComment",      { fg = "#44475a", italic = true }) -- #
  hl(0, "AtomLineTag",          { fg = "#FF79C6" })              -- :tag:
  hl(0, "AtomLinePerson",       { fg = "#8BE9FD" })              -- ~person
  hl(0, "AtomLinePlace",        { fg = "#FFB86C" })              -- @place
  hl(0, "AtomLineDeadline",     { fg = "#FF5555", underline = true })
  hl(0, "AtomLineSeparator",    { fg = "#6272a4", italic = true })
  hl(0, "AtomLineTime",         { fg = "#8BE9FD", italic = false })

  vim.cmd([[
    syntax clear
    syntax match AtomLineTodo "\[\.\]"
    syntax match AtomLineDoing "\[/\]"
    syntax match AtomLineActive "\[-\]"
    syntax match AtomLineDone "\[x\]"
    syntax match AtomLineCompleted "\[+\]"
    syntax match AtomLineMigrate "\[>\]"
    syntax match AtomLineContinuation "^\.\..*$"
    syntax match AtomLineComment "^#.*$"
    syntax match AtomLineTime "[0-9-]\{10} [0-9:]\{5} [A-Za-z]\{3}"
    syntax match AtomLineSeparator "[|]\{1,2}"
    syntax match AtomLineTag ":[^:]\+:"
    syntax match AtomLinePerson "\~[^ ]\+"
    syntax match AtomLinePlace "@[^ ]\+"
    syntax match AtomLineDeadline "![0-9-]\+"
  ]])
end

-- =============================================================================
-- 3. 核心功能函數
-- =============================================================================

-- 分組循環切換邏輯
function M.toggle_status()
  local line = vim.api.nvim_get_current_line()

  -- 第一組：一般任務循環 [.] -> [/] -> [x]
  local group1_states = { "%[%.%]", "%[/%]", "%[x%]" }
  local group1_next   = { "[.]", "[/]", "[x]" }

  -- 第二組：活動項目循環 [-] -> [+]
  local group2_states = { "%[%-%]", "%[%+%]" }
  local group2_next   = { "[-]", "[+]" }

  -- 檢查是否屬於第一組
  for i, s in ipairs(group1_states) do
    if line:find(s) then
      local next_idx = (i % #group1_next) + 1
      vim.api.nvim_set_current_line(line:gsub(s, group1_next[next_idx], 1))
      return
    end
  end

  -- 檢查是否屬於第二組
  for i, s in ipairs(group2_states) do
    if line:find(s) then
      local next_idx = (i % #group2_next) + 1
      vim.api.nvim_set_current_line(line:gsub(s, group2_next[next_idx], 1))
      return
    end
  end
end

-- 篩選功能：包含 [.] [/] [-]
function M.filter_unfinished()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local qf_list = {}
  local bufnr = vim.api.nvim_get_current_buf()
  for i, line in ipairs(lines) do
    if line:find("%[%.%]") or line:find("%[/%]") or line:find("%[%-%]") then
      table.insert(qf_list, { 
        bufnr = bufnr, 
        lnum = i, 
        text = line:gsub("^%s+", "") 
      })
    end
  end
  if #qf_list > 0 then
    vim.fn.setqflist(qf_list)
    vim.cmd("copen")
  else
    print("All tasks and activities are clear!")
  end
end

-- 摺疊邏輯
function M.fold_expr(lnum)
  local line = vim.fn.getline(lnum)
  if line:match("^%.%.") or line:match("^#") then return "1" end
  return "0"
end

-- 智慧續行
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
