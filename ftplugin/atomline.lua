local al = require("atomline")
local set = vim.opt_local

-- 1. 執行高亮
al.apply_syntax()

-- 2. 編輯器基礎設定
set.expandtab = true
set.shiftwidth = 2
set.softtabstop = 2
set.commentstring = "# %s"

-- 3. 自動摺疊
set.foldmethod = "expr"
set.foldexpr = "v:lua.require'atomline'.fold_expr(v:lnum)"
set.foldlevel = 99

-- 4. 快捷鍵綁定 (僅限目前這個 .aln 檔案)
local opts = { buffer = true, silent = true }

vim.keymap.set('n', '<leader>x', al.toggle_status, { buffer = true, desc = "AtomLine: Toggle Status" })
vim.keymap.set('n', '<leader>ts', al.insert_timestamp, { buffer = true, desc = "AtomLine: Insert Timestamp" })
vim.keymap.set('i', '<CR>', al.smart_newline, { buffer = true, expr = true })
vim.keymap.set('n', 'za', 'za', opts)
