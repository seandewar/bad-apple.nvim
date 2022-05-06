local api = vim.api
local fn = vim.fn

local util = require "bad-apple.util"

if fn.has "nvim-0.7" == 0 then
  util.warn "Neovim version 0.7+ is required"
  return
end

local data_dir

api.nvim_create_user_command("BadApple", function()
  if not data_dir then
    data_dir = fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
      .. "/data"
  end
  require("bad-apple").play(
    data_dir .. "/frames.txt",
    { data_dir .. "/audio.mp3", data_dir .. "/audio.ogg" },
    48,
    19,
    30
  )
end, {
  desc = "Watch Bad Apple",
})
