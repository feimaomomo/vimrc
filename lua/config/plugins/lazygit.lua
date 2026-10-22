-- nvim v0.8.0
return {
  "kdheepak/lazygit.nvim",
  lazy = true,
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  -- optional for floating window border decoration
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    -- 👇 in this section, choose your own keymappings!
    {
      "<leader>g",
      mode = { "n", "v" },
      "<cmd>LazyGit<cr>",
      desc = "LazyGit",
    },
  },
  init = function()
    -- lazygit/nvim.yml makes `e` hand files back to this Neovim instead of
    -- nesting another nvim inside the floating terminal.
    local config_dir = vim.fn.stdpath("config") .. "/lazygit/"
    vim.g.lazygit_use_custom_config_file_path = 1
    vim.g.lazygit_config_file_path = { config_dir .. "config.yml", config_dir .. "nvim.yml" }
    vim.env.NVIM_LAZYGIT_EDIT = vim.fn.tempname()

    -- Runs after lazygit exits and focus is back in the window it was opened from.
    vim.g.lazygit_on_exit_callback = function()
      local requests = vim.env.NVIM_LAZYGIT_EDIT
      if vim.fn.filereadable(requests) == 0 then
        return
      end
      local entries = vim.fn.readfile(requests)
      vim.fn.delete(requests)
      for _, entry in ipairs(entries) do
        local file, line = entry:match("^(.*)\t(%d+)$")
        vim.cmd.edit(vim.fn.fnameescape(file or entry))
        if line then
          vim.cmd(line)
        end
      end
    end
  end,
}
