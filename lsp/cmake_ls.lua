return {
  cmd = { 'cmake-language-server' }, -- 如果 brew 安裝後不在 PATH，可改成絕對路徑
  -- A newer pygls in ~/.local (user site) shadows the 1.x it needs; use only its own env.
  cmd_env = { PYTHONNOUSERSITE = '1' },
  filetypes = { 'cmake' },
  root_markers = {
    'CMakeLists.txt',
    'compile_commands.json',
    '.git',
  },
  init_options = {
    buildDirectory = 'build', -- 預設 build 資料夾
  },
}
