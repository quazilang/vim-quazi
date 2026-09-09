vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.cmd("runtime plugin/quazi.lua")

assert(vim.filetype.match({ filename = "model.qz" }) == "quazi")

local config = vim.lsp.config.quazi
local command = vim.env.QUAZI_LSP_COMMAND
if command == nil or command == "" then
  command = "qz"
end
assert(vim.deep_equal(config.cmd, { command, "lsp" }))
assert(vim.deep_equal(config.filetypes, { "quazi" }))
assert(vim.deep_equal(config.root_markers, { "quazi.toml", ".git" }))
