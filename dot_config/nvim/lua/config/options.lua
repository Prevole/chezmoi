-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Clipboard: sync with system clipboard via OSC 52 (works through Zellij + Ghostty)
vim.opt.clipboard = "unnamedplus"

-- Enable mouse support (allows mouse selection to interact with clipboard)
vim.opt.mouse = "a"

-- Use OSC 52 clipboard provider so clipboard works through terminal multiplexers (Zellij)
if vim.env.SSH_TTY ~= nil or os.getenv("ZELLIJ") ~= nil then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end
