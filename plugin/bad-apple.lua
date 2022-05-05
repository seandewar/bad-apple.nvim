local api = vim.api
local fn = vim.fn

if fn.has "nvim-0.7" == 0 then
  api.nvim_echo(
    { { "[bad-apple] Neovim version 0.7+ is required!", "WarningMsg" } },
    true,
    {}
  )
  return
end

api.nvim_create_user_command("BadApple", function()
  require("bad-apple").start()
end, {
  desc = "Watch Bad Apple",
})
