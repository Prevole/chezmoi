return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    default_component_configs = {
      symlink_target = {
        enabled = true,
        text_format = " 󰌷 %s", -- icône nerd font "link"
        highlight = "NeoTreeSymbolicLinkTarget",
      },
      name = {
        highlight_opened_files = true,
      },
    },
    filesystem = {
      filtered_items = {
        visible = true, -- fichiers cachés visibles mais grisés
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
  },
  config = function(_, opts)
    require("neo-tree").setup(opts)

    -- Couleur distincte pour la cible affichée après le symlink (ex: "-> ../modules/...")
    vim.api.nvim_set_hl(0, "NeoTreeSymbolicLinkTarget", { fg = "#7aa2f7", italic = true })
    -- Couleur distincte pour le nom du fichier symlink lui-même
    vim.api.nvim_set_hl(0, "NeoTreeFileSymLink", { fg = "#bb9af7", bold = true })
  end,
}
