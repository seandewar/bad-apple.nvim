local api = vim.api
local uv = vim.loop

local sound = require "bad-apple.sound"
local util = require "bad-apple.util"

local M = {}
local ns = api.nvim_create_namespace "bad-apple"

local function read_frames(file)
  local frames = {}
  local frame
  local skip_line = false
  for line in io.lines(file) do
    if skip_line then
      skip_line = false
    else
      if line:match "^%d+$" then
        frames[#frames + 1] = frame
        frame = {}
        skip_line = true
      else
        frame[#frame + 1] = { { line, "" } }
      end
    end
  end
  return frames
end

local function time_string(ms)
  local secs = math.floor(ms / 1000)
  local mins = math.floor(secs / 60)
  return ("%02d:%02d.%03d"):format(mins, secs % 60, ms % 1000)
end

function M.play(frames_fname, audio_fnames, width, height, fps)
  local frames = read_frames(frames_fname)
  local buf = api.nvim_create_buf(false, true)
  if buf == 0 then
    util.error "failed to create buffer"
  end
  api.nvim_buf_set_name(buf, "[bad-apple buffer #" .. buf .. "]")
  api.nvim_buf_set_option(buf, "modifiable", false)
  api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  local win = api.nvim_open_win(buf, true, {
    style = "minimal",
    border = "rounded",
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, (api.nvim_get_option "lines" - height) / 2),
    col = math.max(0, (api.nvim_get_option "columns" - width) / 2),
  })
  if win == 0 then
    api.nvim_buf_delete(buf, {})
    util.error "failed to create window"
  end

  local sound_ctx, music_id
  local ok, result = pcall(sound.new_context)
  if not ok then
    util.warn("couldn't initialize sound: " .. result)
  else
    sound_ctx = result
    ok, result = pcall(sound_ctx.play, sound_ctx, audio_fnames)
    if not ok then
      util.warn(result)
    else
      music_id = result
      util.echo "providing sound with libcanberra"
    end
  end

  local frame_timer = uv.new_timer()

  local function cleanup()
    if frame_timer:is_active() then
      frame_timer:stop()
      frame_timer:close()
    end
    if sound_ctx and music_id then
      ok, result = pcall(sound_ctx.stop, sound_ctx, music_id)
      if not ok then
        util.warn(result)
      end
      ok, result = pcall(sound_ctx.delete, sound_ctx)
      if not ok then
        util.warn(result)
      end
      sound_ctx = nil
    end
  end

  local ms_per_frame = 1000 / fps
  local runtime_ms = #frames * ms_per_frame
  local frame_scheduled = false
  local frame_extmark
  local start_ms = uv.now()

  frame_timer:start(0, ms_per_frame, function()
    if frame_scheduled then
      return
    end
    local elapsed_ms = uv.now() - start_ms
    local frame_nr = math.floor(math.min(#frames, elapsed_ms / ms_per_frame))

    vim.schedule(function()
      if not api.nvim_buf_is_valid(buf) then
        return
      end

      frame_extmark = api.nvim_buf_set_extmark(buf, ns, 0, 0, {
        id = frame_extmark,
        virt_text = {
          {
            ("%s / %s, frame: %d"):format(
              time_string(elapsed_ms),
              time_string(runtime_ms),
              frame_nr
            ),
            "",
          },
        },
        virt_lines = frames[frame_nr],
      })
      frame_scheduled = false
    end)

    frame_scheduled = true
    if frame_nr == #frames then
      cleanup()
      vim.schedule(function()
        if api.nvim_buf_is_valid(buf) then
          api.nvim_buf_delete(buf, {})
        end
      end)
    end
  end)

  api.nvim_create_autocmd("BufUnload", {
    once = true,
    buffer = buf,
    callback = function()
      cleanup()
      if api.nvim_win_is_valid(win) then
        api.nvim_win_close(win, true)
      end
    end,
  })
end

return M
