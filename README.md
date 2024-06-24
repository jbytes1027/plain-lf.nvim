# plain-lf.nvim

[Lf](https://github.com/gokcehan/lf) integration plugin for neovim with no dependencies besides `lf`.

## Install

Install using your package manager. This plugin _does not set_ Neovim keymaps by default, you will need to set your own keymaps using the exposed [api](#api). See below [Lazy](https://github.com/folke/lazy.nvim) configuration for example.

```lua
{
  "jbytes1027/plain-lf.nvim",
  config = function()
    require("plain-lf-nvim").setup({ replace_netrw = true })
    vim.api.nvim_set_keymap("n", "<leader>ef", "", {
      noremap = true,
      callback = function()
        require("lf-nvim").open(true)
      end,
    })
  end,
}
```

## Configuration

Configure by calling `setup(opts)` with an `opts` described in `lua/plain-lf-nvim.lua`.

## API

### `open(select_current_file: boolean)`

Opens `lf` in a fullscreen floating window.

When `select_current_file` is set to `true`, `lf` will focus on the file in the current buffer on load.
