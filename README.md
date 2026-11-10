# Quazi for Neovim and Vim

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

The Unicode and formatting protocol check uses the same setup. Through
Neovim's own LSP client it sends incremental edits next to non-BMP text
(`λ🙂 你好🎉`), compares the server's diagnostic and hover positions with
Neovim's UTF-16 indexes, and requires whole-document formatting to equal
`qz fmt` output for the same text:

```bash
QUAZI_LSP_COMMAND=/absolute/path/to/qz \
XDG_STATE_HOME=/tmp/nvim-quazi-state \
NVIM_LOG_FILE=/tmp/nvim-quazi.log \
nvim --headless -u NONE -i NONE -c 'luafile tests/lsp-unicode.lua' -c qa
```

`QUAZI_LSP_COMMAND` accepts the path to one executable, so it is useful during
local development when the compiler is not installed on `PATH`; normal editor
use continues to launch `qz lsp`. The command above uses POSIX environment
syntax; set the same variable with your shell's platform-specific syntax.

## Vim support

Ordinary Vim does not implement Neovim's built-in LSP API, but this package
also supports Vim 8+ through [vim-lsp](https://github.com/prabirshrestha/vim-lsp).
Install `vim-lsp` and this package, ensuring `vim-lsp` is loaded first. The
Vim adapter assigns the `quazi` filetype to `.qz` files and registers `qz lsp`.
It honors the same `QUAZI_LSP_COMMAND` override. Completion mappings and UI
preferences belong to the user's `vim-lsp` configuration.
