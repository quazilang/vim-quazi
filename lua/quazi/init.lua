local M = {}

function M.lsp_config()
  local command = vim.env.QUAZI_LSP_COMMAND
  if command == nil or command == "" then
    command = "qz"
  end
  return {
    cmd = { command, "lsp" },
    filetypes = { "quazi" },
    root_markers = { "quazi.toml", ".git" },
  }
end

return M
