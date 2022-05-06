local ffi, ca

local function ca_error(msg, code)
  error(("[libcanberra] %s: %s"):format(msg, ffi.string(ca.ca_strerror(code))))
end

local function ca_try(code, msg, err_cleanup_fn)
  if code ~= 0 then
    if err_cleanup_fn then
      err_cleanup_fn()
    end
    ca_error(msg, code)
  end
end

local Context = {}

local function check_valid(ctx)
  if not ctx.ca_ctx then
    error "sound context already deleted"
  end
end

function Context:play(fnames)
  check_valid(self)
  if type(fnames) == "string" then
    fnames = { fnames }
  end

  local id = self.next_id
  self.next_id = self.next_id + 1
  for _, fname in ipairs(fnames) do
    if
      ca.ca_context_play(
        self.ca_ctx,
        id,
        "media.filename",
        fname,
        "canberra.cache-control",
        "volatile",
        nil
      ) == 0
    then
      return id
    end
  end

  ca_error("failed to play sounds: " .. table.concat(fnames, ", "))
end

function Context:stop(id)
  check_valid(self)
  ca_try(ca.ca_context_cancel(self.ca_ctx, id), "failed to cancel sound")
end

function Context:delete()
  check_valid(self)
  local ca_ctx = self.ca_ctx
  self.ca_ctx = nil
  ca_try(ca.ca_context_destroy(ca_ctx), "failed to destroy context")
end

local M = {
  libcanberra_fname = "canberra.so.0",
}

function M.new_context()
  local ok
  if not ffi then
    ok, ffi = pcall(require, "ffi")
    if not ok then
      error "LuaJIT FFI is not available"
    end

    ok, ca = pcall(ffi.load, M.libcanberra_fname)
    if not ok then
      error('failed to load libcanberra ("' .. M.libcanberra_fname .. '")')
    end

    ffi.cdef [[
      const char *ca_strerror(int);

      typedef struct ca_context ca_context;
      int ca_context_create(ca_context **);
      int ca_context_destroy(ca_context *);
      int ca_context_open(ca_context *);
      int ca_context_play(ca_context *, uint32_t, ...);
      int ca_context_cancel(ca_context *, uint32_t);
    ]]
  end

  local ca_ctx_ptr = ffi.new "ca_context *[1]"
  ca_try(ca.ca_context_create(ca_ctx_ptr), "failed to create context")
  ca_try(
    ca.ca_context_open(ca_ctx_ptr[0]),
    "failed to connect to the sound system",
    function()
      ca.ca_context_destroy(ca_ctx_ptr[0])
    end
  )

  return setmetatable({
    ca_ctx = ca_ctx_ptr[0],
    next_id = 1,
  }, {
    __index = Context,
  })
end

return M
