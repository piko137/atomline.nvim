local M = {}

-- 1. 視覺高亮設定
function M.setup()
  vim.cmd([[syntax on]])
  local hl = vim.api.nvim_set_hl
  
  -- 定義顏色群組
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

-- 2. 狀態循環切換
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

-- 3. 摺疊邏輯
function M.fold_expr(lnum)
  local line = vim.fn.getline(lnum)
  if line:match("^%.%.") or line:match("^#") then
    return "1"
  end
  return "0"
end

-- 4. 智慧續行 (Insert Mode)
function M.smart_newline()
  local line = vim.api.nvim_get_current_line()
  if line:find("^%[") or line:find("^%.%.") then
    return vim.api.nvim_replace_termcodes("<CR>.. ", true, false, true)
  else
    return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  end
end

-- 5. 插入時間戳記
function M.insert_timestamp()
  local timestamp = os.date("%Y-%m-%d %H:%M %a | ")
  vim.api.nvim_put({timestamp}, "c", true, true)
end

return M
