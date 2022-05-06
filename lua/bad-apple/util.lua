local api = vim.api

local M = {}

function M.error(msg)
  error("[bad-apple] " .. msg)
end

function M.warn(msg)
  api.nvim_echo({ { "[bad-apple] " .. msg, "WarningMsg" } }, true, {})
end

function M.echo(msg)
  api.nvim_echo({ { "[bad-apple] " .. msg } }, false, {})
end

return M
