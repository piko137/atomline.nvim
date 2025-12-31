local M = {}

-- =============================================================================
-- 1. 總入口：整合視覺、設定與快捷鍵
-- =============================================================================
function M.setup()
  -- 啟動高亮引擎
  M.apply_syntax()

  -- 緩衝區局部設定 (Buffer-local Options)
  local set = vim.opt_local
  set.expandtab = true      -- 使用空格
  set.shiftwidth = 2        -- 縮排 2 格
  set.softtabstop = 2
  set.commentstring = "# %s" -- 設定註解格式

  -- 自動摺疊設定 (.. 與 # 摺疊進上一行任務)
  set.foldmethod = "expr"
  set.foldexpr = "v:lua.require'atomline'.fold_expr(v:lnum)"
  set.foldlevel = 99        -- 預設展開

  -- 快捷鍵綁定
  local opts = { buffer = true, silent = true }
  
  -- <leader>x: 循環切換任務狀態 [.] -> [/] -> [x]
  vim.keymap.set('n', '<leader>x', M.toggle_status, { buffer = true, desc = "AtomLine: Toggle Status" })
  
  -- <leader>ts: 插入時間戳記
  vim.keymap.set('n', '<leader>ts', M.insert_timestamp, { buffer = true, desc = "AtomLine: Insert Timestamp" })
  
  -- i_<CR>: 編輯模式下 Enter 自動續行 (..)
  vim.keymap.set('i', '<CR>', M.smart_newline, { buffer = true, expr = true })
  
  -- za: 切換摺疊
  vim.keymap.set('n', 'za', 'za', opts)
end

-- =============================================================================
-- 2. 視覺高亮邏輯
-- =============================================================================
function M.apply_syntax()
  -- 強制啟動原生語法引擎
  vim.cmd([[
    syntax enable
    if !exists("g:syntax_on")
      syntax on
    endif
  ]])

  local hl = vim.api.nvim_set_hl
  
  -- 定義顏色群組 (Highlight Groups)
  hl(0, "AtomLineTodo",         { fg = "#FF5555", bold = true }) -- 紅 [.]
  hl(0, "AtomLineDoing",        { fg = "#F1FA8C", bold = true }) -- 黃 [/]
  hl(0, "AtomLineDone",         { fg = "#50FA7B" })              -- 綠 [x]
  hl(0, "AtomLineMigrate",      { fg = "#BD93F9" })              -- 紫 [>]
  hl(0, "AtomLineContinuation", { fg = "#6272a4" })              -- 灰 ..
  hl(0, "AtomLineComment",      { fg = "#44475a", italic = true }) -- 註解 #
  hl(0, "AtomLineTag",          { fg = "#FF79C6" })              -- 粉 :tag:
  hl(0, "AtomLinePerson",       { fg = "#8BE9FD" })              -- 青 ~person
  hl(0, "AtomLinePlace",        { fg = "#FFB86C" })              -- 橘 @place
  hl(0, "AtomLineDeadline",     { fg = "#FF5555", underline = true }) -- 底線 !date
  hl(0, "AtomLineSeparator",    { fg = "#6272a4", italic = true })    -- 斜體 ||

  -- 綁定正則表達式規則
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

-- =============================================================================
-- 3. 核心功能函數
-- =============================================================================

-- 狀態循環切換
function M.toggle_status()
  local line = vim.api.nvim_get_current_line()
  local states = { "%[%.%]", "%[/%]", "%[x%]" }
  local next_states = { "[.]", "[/]", "[x]" }
  
  for i, s in ipairs(states) do
    if line:find(s) then
      local next_idx = (i % #next_states) + 1
      local new_line = line:gsub(s, next_states[next_idx], 1)
      vim.api.nvim_set_current_line(new_line)
      return
    end
  end
end

-- 摺疊表達式
function M.fold_expr(lnum)
  local line = vim.fn.getline(lnum)
  if line:match("^%.%.") or line:match("^#") then
    return "1" -- 屬於第 1 層摺疊
  end
  return "0"   -- 不摺疊
end

-- 智慧續行 (Enter)
function M.smart_newline()
  local line = vim.api.nvim_get_current_line()
  -- 如果該行以任務標籤或續行符號開頭，自動補上 ".."
  if line:find("^%[") or line:find("^%.%.") then
    return vim.api.nvim_replace_termcodes("<CR>.. ", true, false, true)
  else
    return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  end
end

-- 插入當前時間戳記
function M.insert_timestamp()
  local timestamp = os.date("%Y-%m-%d %H:%M %a | ")
  vim.api.nvim_put({timestamp}, "c", true, true)
end

return M
