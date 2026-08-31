if vim.fn.has("nvim-0.11") == 0 then
  vim.notify("nvim-quazi requires Neovim 0.11 or newer", vim.log.levels.WARN)
  return
end

vim.filetype.add({ extension = { qz = "quazi" } })

vim.lsp.config("quazi", require("quazi").lsp_config())
vim.lsp.enable("quazi")
