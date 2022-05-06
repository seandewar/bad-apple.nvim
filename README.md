# bad-apple.nvim

[Bad Apple!!](https://www.youtube.com/watch?v=UkgK8eUdpAo) for Neovim v0.7+.  

Written in Lua with no required external dependencies. However, optional support
for playing music is included if libcanberra and the Lua JIT FFI is available.

Inspired by [ryoppippi/bad-apple.vim](https://github.com/ryoppippi/bad-apple.vim),
and also uses frame data from [Reyansh-Khobragade/bad-apple-nodejs](https://github.com/Reyansh-Khobragade/bad-apple-nodejs).

Run with `:BadApple`.

If the plugin cannot find libcanberra, you may manually specify its location:

```lua
require("bad-apple.sound").libcanberra_fname = "/path/to/libcanberra"
```

## Asciicast

[![Click here to see an asciicast](https://asciinema.org/a/ctgDbBZF9cdjcVgiLnu1IeTUL.svg)](https://asciinema.org/a/ctgDbBZF9cdjcVgiLnu1IeTUL)
