vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.cmd("runtime plugin/quazi.lua")

assert(vim.filetype.match({ filename = "model.qz" }) == "quazi")

local config = vim.lsp.config.quazi
assert(vim.deep_equal(config.cmd, { "qz", "lsp" }))
assert(vim.deep_equal(config.filetypes, { "quazi" }))
assert(vim.deep_equal(config.root_markers, { "quazi.toml", ".git" }))
