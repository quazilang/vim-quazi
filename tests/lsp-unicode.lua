-- Real-client Unicode and formatting protocol check: Neovim's built-in LSP
-- client sends incremental UTF-16 edits next to non-BMP text, then the test
-- compares diagnostics and hover positions with Neovim's own UTF-16 indexes
-- and the formatted buffer with `qz fmt` output for the same text.
local command = assert(vim.env.QUAZI_LSP_COMMAND, "set QUAZI_LSP_COMMAND to the qz executable")
assert(command ~= "", "set QUAZI_LSP_COMMAND to the qz executable")

vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.cmd("runtime plugin/quazi.lua")
vim.cmd("filetype on")

local root = vim.fn.tempname()
local reference = vim.fn.tempname()
local client

local function quazi_client()
  local clients = vim.lsp.get_clients({ bufnr = 0, name = "quazi" })
  return clients[1]
end

local manifest = { "[package]", 'name = "lsp-unicode"', 'version = "0.1.0"', "", "[build]", 'entry = "src/main.qz"' }

local function utf16_column(line, byte_index)
  return vim.str_utfindex(line, "utf-16", byte_index)
end

local function request(method, params)
  local response = vim.lsp.buf_request_sync(0, method, params, 5_000)
  return response and response[client.id] and response[client.id].result or nil
end

local function run()
  assert(vim.fn.mkdir(vim.fs.joinpath(root, "src"), "p") == 1)
  vim.fn.writefile(manifest, vim.fs.joinpath(root, "quazi.toml"))
  local source_path = vim.fs.joinpath(root, "src", "main.qz")
  vim.fn.writefile({
    "fn main() i32 {",
    '    const label: str = "λ🙂 你好"; // 🚀 комментарий',
    "    const answer:i32=41;",
    "    ret answer;",
    "}",
  }, source_path)

  vim.cmd.edit(vim.fn.fnameescape(source_path))
  assert(vim.bo.filetype == "quazi", "Quazi filetype was not detected")
  assert(vim.wait(10_000, function()
    client = quazi_client()
    return client ~= nil and client.initialized
  end, 50), "Quazi LSP did not initialize")

  -- Incremental edits: grow the string after the emoji, then add a statement
  -- whose unknown name follows non-BMP text on the same line.
  local line = vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]
  local after = assert(line:find("你好", 1, true)) + #"你好" - 1
  vim.api.nvim_buf_set_text(0, 1, after, 1, after, { "🎉" })
  vim.api.nvim_buf_set_lines(0, 2, 2, false, { '    const mark: str = "🙂🙂"; const total: i32 = missing_name;' })
  local edited = vim.api.nvim_buf_get_lines(0, 2, 3, false)[1]
  local missing = assert(edited:find("missing_name", 1, true)) - 1

  local diagnostic
  assert(vim.wait(10_000, function()
    for _, item in ipairs(vim.diagnostic.get(0)) do
      if item.message:find("missing_name", 1, true) then
        diagnostic = item
        return true
      end
    end
    return false
  end, 50), "no diagnostic for the unknown name after the edits")
  assert(diagnostic.lnum == 2, "diagnostic line " .. diagnostic.lnum)
  -- vim.diagnostic stores byte columns converted from the server's UTF-16 range.
  assert(diagnostic.col == missing, ("diagnostic byte column %d, expected %d"):format(diagnostic.col, missing))

  local total = assert(edited:find("total", 1, true)) - 1
  local hover = request("textDocument/hover", {
    textDocument = { uri = vim.uri_from_bufnr(0) },
    position = { line = 2, character = utf16_column(edited, total + 1) },
  })
  assert(hover ~= nil and hover.range ~= nil, "no hover after non-BMP text")
  assert(hover.range.start.character == utf16_column(edited, total),
    ("hover starts at UTF-16 %d, expected %d"):format(hover.range.start.character, utf16_column(edited, total)))

  -- Remove the error, then format through the client.
  -- Misindent the statement and leave trailing blanks after the emoji.
  local fixed = "        " .. vim.trim(edited:gsub("missing_name", "41")) .. "   "
  vim.api.nvim_buf_set_lines(0, 2, 3, false, { fixed })
  local unformatted = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  vim.lsp.buf.format({ async = false, timeout_ms = 5_000, name = "quazi" })
  local formatted = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert(not vim.deep_equal(unformatted, formatted), "formatting changed nothing")

  -- `qz fmt` on a project holding the unformatted text must agree.
  assert(vim.fn.mkdir(vim.fs.joinpath(reference, "src"), "p") == 1)
  vim.fn.writefile(manifest, vim.fs.joinpath(reference, "quazi.toml"))
  local reference_path = vim.fs.joinpath(reference, "src", "main.qz")
  vim.fn.writefile(unformatted, reference_path)
  local result = vim.system({ command, "fmt" }, { cwd = reference, text = true }):wait()
  assert(result.code == 0, "qz fmt failed: " .. (result.stderr or ""))
  local expected = vim.fn.readfile(reference_path)
  assert(vim.deep_equal(formatted, expected),
    "LSP formatting differs from qz fmt:\n" .. table.concat(formatted, "\n") .. "\n---\n" .. table.concat(expected, "\n"))
  assert(table.concat(formatted, "\n"):find("λ🙂 你好🎉", 1, true), "formatting lost non-BMP text")

  local shutdown = client:request_sync("shutdown", nil, 5_000)
  assert(shutdown ~= nil and shutdown.err == nil, "Quazi LSP did not accept shutdown")
  assert(client:notify("exit"), "Quazi LSP did not accept exit")
end

local ok, failure = xpcall(run, debug.traceback)
if client ~= nil then
  client:stop(true)
  vim.wait(5_000, function()
    return quazi_client() == nil
  end, 50)
end
vim.cmd("enew!")
vim.cmd("silent! %bwipeout!")
local removed = vim.fn.delete(root, "rf") + vim.fn.delete(reference, "rf")
if not ok then
  error(failure)
end
assert(removed == 0, "failed to remove the temporary Quazi projects")
print("PASS lsp unicode: incremental UTF-16 edits, diagnostic and hover positions, formatting equals qz fmt")
