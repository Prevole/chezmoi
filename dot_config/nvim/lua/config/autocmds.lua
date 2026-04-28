-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto re-add nvim config files to chezmoi after save
vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("chezmoi_readd_nvim", { clear = true }),
  pattern = vim.fn.expand("~/.config/nvim/*"),
  callback = function(event)
    vim.system({ "chezmoi", "re-add", event.file }, { detach = true })
  end,
  desc = "Re-add saved nvim config files to chezmoi",
})
