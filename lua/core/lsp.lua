local capabilities = vim.lsp.protocol.make_client_capabilities()
local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if has_cmp then
  capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end
-- File watching can exhaust descriptor limits on macOS and large clusters.
-- Servers still receive open/change/save notifications for edited buffers.
if capabilities.workspace then
  capabilities.workspace.didChangeWatchedFiles = nil
end

local default_register_capability = vim.lsp.handlers["client/registerCapability"]
local function register_capability_without_watchers(err, result, ctx, config)
  if result and result.registrations then
    result = vim.deepcopy(result)
    result.registrations = vim.tbl_filter(function(registration)
      return registration.method ~= "workspace/didChangeWatchedFiles"
    end, result.registrations)
  end
  return default_register_capability(err, result, ctx, config)
end

vim.lsp.config("*", {
  capabilities = capabilities,
  handlers = {
    ["client/registerCapability"] = register_capability_without_watchers,
  },
})

vim.lsp.enable({
  "clangd_ls",
  "lua_ls",
  "python_ls",
  "ruff_ls",
  "cmake_ls",
})

local diagnostic_signs = {
  text = {
    [vim.diagnostic.severity.ERROR] = "󰅚 ",
    [vim.diagnostic.severity.WARN] = "󰀪 ",
    [vim.diagnostic.severity.INFO] = "󰋽 ",
    [vim.diagnostic.severity.HINT] = "󰌶 ",
  },
  numhl = {
    [vim.diagnostic.severity.ERROR] = "ErrorMsg",
    [vim.diagnostic.severity.WARN] = "WarningMsg",
  },
}

vim.diagnostic.config({
  virtual_lines = true,
  virtual_text = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = true,
  },
  signs = diagnostic_signs,
})

-- vim.diagnostic.config is global, so the toggle state must be global too.
local diagnostics_shown = true
local function toggle_diagnostics()
  diagnostics_shown = not diagnostics_shown
  vim.diagnostic.config({
    underline = diagnostics_shown,
    virtual_lines = diagnostics_shown,
    signs = diagnostics_shown and diagnostic_signs or false,
  })
end

local function formatting_client(client, filetype)
  if filetype == "python" then
    return client.name == "ruff_ls"
  end
  if vim.tbl_contains({ "c", "cpp", "objc", "objcpp", "cuda" }, filetype) then
    return client.name == "clangd_ls"
  end
  return client:supports_method("textDocument/formatting")
end

local function format_buffer(bufnr)
  local filetype = vim.bo[bufnr].filetype
  local filter = function(client)
    return formatting_client(client, filetype) and client:supports_method("textDocument/formatting", bufnr)
  end
  -- Buffers without a formatting server (txt, markdown, ...) save silently.
  if #vim.tbl_filter(filter, vim.lsp.get_clients({ bufnr = bufnr })) == 0 then
    return
  end
  vim.lsp.buf.format({
    bufnr = bufnr,
    async = false,
    timeout_ms = 3000,
    filter = filter,
  })
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("lsp-format-on-save", { clear = true }),
  callback = function(event)
    format_buffer(event.buf)
  end,
})

-- Define LSP-related keymaps
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    vim.keymap.set('n', 'gd', function()
      require('snacks').picker.lsp_definitions()
    end, { buffer = event.buf, desc = 'LSP: Goto Definition' })

    vim.keymap.set('n', 'gD', function()
      local win = vim.api.nvim_get_current_win()
      local width = vim.api.nvim_win_get_width(win)
      local height = vim.api.nvim_win_get_height(win)

      -- Mimic tmux formula: 8 * width - 20 * height
      local value = 8 * width - 20 * height
      if value < 0 then
        vim.cmd 'split'  -- vertical space is more: horizontal split
      else
        vim.cmd 'vsplit' -- horizontal space is more: vertical split
      end

      vim.lsp.buf.definition()
    end, { buffer = event.buf, desc = 'LSP: Goto Definition (split)' })
    vim.keymap.set('n', 'gr', function()
      require('snacks').picker.lsp_references()
    end, { buffer = event.buf, desc = 'LSP: Goto References' })

    vim.keymap.set('n', 'gR', vim.lsp.buf.rename, { buffer = event.buf, desc = 'LSP: Rename' })
    vim.keymap.set('n', '<leader>t', toggle_diagnostics, { buffer = event.buf, desc = 'LSP: Toggle diagnostics display' })

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    -- inlay hints
    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
    end
    -- folding
    if client and client:supports_method('textDocument/foldingRange', event.buf) then
      local win = vim.fn.bufwinid(event.buf)
      if win ~= -1 then
        vim.wo[win][0].foldmethod = 'expr'
        vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
      end
    end
    -- References under the cursor are highlighted by vim-illuminate.
  end,
})
