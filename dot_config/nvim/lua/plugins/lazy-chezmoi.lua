-- Re-add lazy-lock.json to chezmoi after Lazy updates/installs
return {
  "folke/lazy.nvim",
  opts = function(_, opts)
    opts.change_detection = opts.change_detection or {}
    return opts
  end,
  config = function(_, opts)
    -- Hook into Lazy's done event to sync lazy-lock.json with chezmoi
    vim.api.nvim_create_autocmd("User", {
      group = vim.api.nvim_create_augroup("chezmoi_readd_lazy_lock", { clear = true }),
      pattern = { "LazyInstall", "LazyUpdate", "LazySync", "LazyRestore", "LazyClean" },
      callback = function()
        local lockfile = vim.fn.expand("~/.config/nvim/lazy-lock.json")
        vim.system({ "chezmoi", "re-add", lockfile }, { detach = true })
      end,
      desc = "Re-add lazy-lock.json to chezmoi after Lazy operations",
    })
  end,
}
