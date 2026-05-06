-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Clipboard: sync with system clipboard via OSC 52 (works through Zellij + Ghostty)
vim.opt.clipboard = "unnamedplus"

-- Enable mouse support (allows mouse selection to interact with clipboard)
vim.opt.mouse = "a"

-- Use OSC 52 for copy (write) but pbpaste for paste (read) on macOS.
-- Ghostty supports OSC 52 write but not OSC 52 read (paste query), which
-- causes a blocking timeout when p is pressed after y.
if vim.env.SSH_TTY ~= nil or os.getenv("ZELLIJ") ~= nil then
  local is_mac = vim.fn.has("mac") == 1
  vim.g.clipboard = {
    name = "OSC 52 (copy) + pbpaste (paste)",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = is_mac and { "pbpaste" } or require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = is_mac and { "pbpaste" } or require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end
