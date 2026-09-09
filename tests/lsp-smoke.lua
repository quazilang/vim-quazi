local command = assert(vim.env.QUAZI_LSP_COMMAND, "set QUAZI_LSP_COMMAND to the qz executable")
assert(command ~= "", "set QUAZI_LSP_COMMAND to the qz executable")

vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.cmd("runtime plugin/quazi.lua")
vim.cmd("filetype on")

local root = vim.fn.tempname()
local client

local function quazi_client()
  local clients = vim.lsp.get_clients({ bufnr = 0, name = "quazi" })
  return clients[1]
end

local function run()
  assert(vim.fn.mkdir(root, "p") == 1)
  local source_path = vim.fs.joinpath(root, "main.qz")
  vim.fn.writefile({ "[package]", 'name = "lsp-smoke"', 'version = "0.1.0"' }, vim.fs.joinpath(root, "quazi.toml"))
  vim.fn.writefile({ "fn main() void {", "    const answer: i32 = 42;", "    ret;", "}" }, source_path)

  vim.cmd.edit(vim.fn.fnameescape(source_path))
  assert(vim.bo.filetype == "quazi", "Quazi filetype was not detected")

  assert(vim.wait(10_000, function()
    client = quazi_client()
    return client ~= nil and client.initialized
  end, 50), "Quazi LSP did not initialize")

  local function hover_result()
    local line = vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]
    local literal_start = assert(line:find("42", 1, true), "fixture literal is missing")
    local response = vim.lsp.buf_request_sync(0, "textDocument/hover", {
      textDocument = { uri = vim.uri_from_bufnr(0) },
      position = { line = 1, character = literal_start - 1 },
    }, 1_000)
    return response and response[client.id] and response[client.id].result or nil
  end

  local result
  assert(vim.wait(10_000, function()
    result = hover_result()
    return result ~= nil
  end, 50), "Quazi LSP did not return hover information")
  assert(result.contents ~= nil, "hover result lacks contents")

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
vim.cmd.enew()
local removed = vim.fn.delete(root, "rf")
if not ok then
  error(failure)
end
assert(removed == 0, "failed to remove the temporary Quazi project")
