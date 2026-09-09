# Quazi for Neovim

Neovim 0.11+ integration for `.qz` files and the contained Quazi language
server. It uses Neovim's built-in LSP configuration API; `nvim-lspconfig` is
not required.

Install this directory as a Neovim plugin, ensure `qz` is on `PATH`, then open
a `.qz` file. The plugin assigns the `quazi` filetype and starts one
`qz lsp` process per `quazi.toml` project (falling back to `.git`).

The grammar and opaque field-attribute contract live in the sibling
`tree-sitter` project. This plugin intentionally does not register a parser
with `nvim-treesitter`: users can install the maintained `tree-sitter-quazi`
grammar independently.

Verify the static integration with:

```bash
XDG_STATE_HOME=/tmp/nvim-quazi-state \
NVIM_LOG_FILE=/tmp/nvim-quazi.log \
nvim --headless -u NONE -i NONE -c 'luafile tests/headless.lua' -c qa
```

To smoke-test a real Neovim client/server session, build `qz` first and point
the test at that executable. The test opens a temporary Quazi project, waits
for the contained LSP to initialize, requests hover information, and performs
the standard shutdown/exit handshake before cleaning up the test process:

```bash
QUAZI_LSP_COMMAND=/absolute/path/to/qz \
XDG_STATE_HOME=/tmp/nvim-quazi-state \
NVIM_LOG_FILE=/tmp/nvim-quazi.log \
nvim --headless -u NONE -i NONE -c 'luafile tests/lsp-smoke.lua' -c qa
```

`QUAZI_LSP_COMMAND` accepts the path to one executable, so it is useful during
local development when the compiler is not installed on `PATH`; normal editor
use continues to launch `qz lsp`. The command above uses POSIX environment
syntax; set the same variable with your shell's platform-specific syntax.
