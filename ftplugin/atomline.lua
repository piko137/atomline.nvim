local al = require("atomline")
local set = vim.opt_local

-- 1. 基礎編輯器設定
set.expandtab = true
set.shiftwidth = 2
set.softtabstop = 2
set.commentstring = "# %s"

-- 2. 載入語法高亮
al.setup()

-- 3. 設定自動摺疊 (連結到模組函數)
set.foldmethod = "expr"
set.foldexpr = "v:lua.require'atomline'.fold_expr(v:lnum)"
set.foldlevel = 99

-- 4. 快捷鍵綁定 (Buffer-local)
local opts = { buffer = true, silent = true }

vim.keymap.set('n', '<leader>x', al.toggle_status, { buffer = true, silent = true, desc = "Toggle AtomLine Status" })
vim.keymap.set('n', 'za', 'za', opts)
vim.keymap.set('n', '<leader>ts', al.insert_timestamp, { buffer = true, desc = "Insert AtomLine Timestamp" })
vim.keymap.set('i', '<CR>', al.smart_newline, { buffer = true, expr = true })
