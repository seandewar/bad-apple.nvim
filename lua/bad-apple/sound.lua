local api = vim.api
local fn = vim.fn

local M = {}

local PROVIDERS = {
  { exe = "afplay", cmd = { "afplay" } },
  { exe = "paplay", cmd = { "paplay" } },
  { exe = "cvlc", cmd = { "cvlc", "--play-and-exit" } },
}

local sound_provider
function M.detect_provider()
  sound_provider = nil
  for _, provider in ipairs(PROVIDERS) do
    if fn.executable(provider.exe) == 1 then
      api.nvim_echo(
        { { "Providing sound with " .. provider.exe .. "." } },
        true,
        {}
      )
      sound_provider = provider
      return
    end
  end

  local provider_names = {}
  for _, provider in ipairs(PROVIDERS) do
    provider_names[#provider_names + 1] = provider.exe
  end
  if #provider_names > 0 then
    api.nvim_echo({
      { "No sound provider found; you're missing out! Supported are: " },
      { table.concat(provider_names, ", ") .. "." },
    }, true, {})
  end
end

function M.play(name)
  if not sound_provider then
    return -1
  end
  local cmd = vim.deepcopy(sound_provider.cmd)
  cmd[#cmd + 1] = name
  return fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      if code ~= 0 then
        api.nvim_echo({
          {
            "[bad-apple] sound provider exited with non-zero code: " .. code,
            "WarningMsg",
          },
        }, true, {})
      end
    end,
  })
end

function M.stop(job)
  return fn.jobstop(job) == 1
end

return M
