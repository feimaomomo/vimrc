-- leader key to spaceto
vim.g.mapleader = ","
local keymap = vim.keymap -- for conciseness
local opt = { noremap = true, silent = true }

keymap.set("n", "ZZ", "<cmd>wq<cr>", { desc = "save and quit" })
keymap.set("x", "ZZ", "<esc><cmd>wq<cr>", { desc = "save and quit" })
keymap.set("n", "QQ", "ZQ", { desc = "quit without saving" })

keymap.set("n", "<F1>", ":w<cr>")

-- Neovim provides `gcc` for the current line and `gc` for a visual selection.
-- Keep `gcc` in Visual mode as an alias for the native `gc` mapping.
keymap.set("x", "gcc", "gc", { remap = true, desc = "comment selected lines" })

-- F2: toggle terminal in current directory
local term_win = nil
local term_buf = nil
local function close_term()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_close(term_win, true)
  end
  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    vim.api.nvim_buf_delete(term_buf, { force = true })
  end
  term_win = nil
  term_buf = nil
end

local function open_term()
  local cwd = vim.fn.getcwd()
  vim.cmd("botright split")
  term_win = vim.api.nvim_get_current_win()
  vim.cmd("terminal")
  term_buf = vim.api.nvim_get_current_buf()
  vim.bo[term_buf].buflisted = false
  vim.bo[term_buf].bufhidden = "wipe"
  vim.cmd("startinsert")
  vim.cmd("lcd " .. vim.fn.fnameescape(cwd))
end

local function toggle_term()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    close_term()
    return
  end
  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    close_term()
  end
  open_term()
end

keymap.set("n", "<F2>", toggle_term, { noremap = true, silent = true, desc = "toggle terminal (cwd)" })
keymap.set("t", "<F2>", function()
  vim.cmd("stopinsert")
  toggle_term()
end, { noremap = true, silent = true, desc = "toggle terminal (cwd)" })

keymap.set("n", "<F9>", "<cmd>Yazi toggle<cr>", { desc = "toggle Yazi" })

-- Drop Neovim's default gr* LSP mappings; they make the buffer-local `gr`
-- (references) wait for timeoutlen. Rename lives on `gR`.
for _, lhs in ipairs({ "gri", "grr", "gra", "grn", "grt", "grx" }) do
  pcall(vim.keymap.del, "n", lhs)
end
pcall(vim.keymap.del, "x", "gra")

-- barbar --
keymap.set("n", "<leader>1", "<cmd>BufferGoto 1<cr>", opt)
keymap.set("n", "<leader>2", "<cmd>BufferGoto 2<cr>", opt)
keymap.set("n", "<leader>3", "<cmd>BufferGoto 3<cr>", opt)
keymap.set("n", "<leader>4", "<cmd>BufferGoto 4<cr>", opt)
keymap.set("n", "<leader>5", "<cmd>BufferGoto 5<cr>", opt)
keymap.set("n", "<leader>6", "<cmd>BufferGoto 6<cr>", opt)
keymap.set("n", "<leader>7", "<cmd>BufferGoto 7<cr>", opt)
keymap.set("n", "<leader>d", function()
  -- 計算有多少個已載入的普通 buffer
  local buffers = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
  end, vim.api.nvim_list_bufs())

  -- `confirm` asks to save/discard instead of silently dropping changes.
  vim.cmd(#buffers <= 1 and "confirm quit" or "confirm BufferClose")
end, { noremap = true, silent = true, desc = "close buf" })
