local M = {}

function M.lsp_config()
  return {
    cmd = { "qz", "lsp" },
    filetypes = { "quazi" },
    root_markers = { "quazi.toml", ".git" },
  }
end

return M
