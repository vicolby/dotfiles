-- native LSP (nvim 0.11+), servers come from nix (home.nix)
vim.lsp.config('basedpyright', {
  cmd = { 'basedpyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'uv.lock', 'poetry.lock', 'setup.py', 'pyrightconfig.json', '.git' },
  settings = {
    basedpyright = {
      analysis = { typeCheckingMode = 'standard' },  -- gd is the goal, keep diagnostics quiet
    },
  },
})
vim.lsp.enable('basedpyright')
