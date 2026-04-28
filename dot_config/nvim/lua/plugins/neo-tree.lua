return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    default_component_configs = {
      symlink_target = {
        enabled = true,
        text_format = " 󰌷 %s", -- nerd font "link" icon
        highlight = "NeoTreeSymbolicLinkTarget",
      },
      name = {
        highlight_opened_files = true,
      },
    },
    filesystem = {
      filtered_items = {
        visible = true, -- hidden files shown but greyed out
        hide_dotfiles = false,
        hide_gitignored = false,
      },
      -- Sync editor → Neo-tree: automatically reveal the active file in the tree
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
    },
    window = {
      mappings = {
        -- P (uppercase): preview file in editor window, focus stays in Neo-tree
        -- Navigate with j/k to update the preview. Press Enter to actually open the file.
        ["P"] = { "toggle_preview", config = { use_float = false, use_image_nvim = false } },
      },
    },
  },
  config = function(_, opts)
    require("neo-tree").setup(opts)

    -- Distinct color for the symlink target text (e.g. "-> ../modules/...")
    vim.api.nvim_set_hl(0, "NeoTreeSymbolicLinkTarget", { fg = "#7aa2f7", italic = true })
    -- Distinct color for the symlink filename itself
    vim.api.nvim_set_hl(0, "NeoTreeFileSymLink", { fg = "#bb9af7", bold = true })
  end,
}
