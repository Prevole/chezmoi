-- Override terraformls root detection to use only .git as root marker.
-- Using .terraform as a marker causes one terraform-ls instance per subdirectory,
-- leading to dozens of zombie processes and eventual freezes.
--
-- Semantic tokens are disabled for terraformls: Neovim's str_utfindex becomes O(n²)
-- on long lines with complex interpolations inside heredocs, causing a full freeze.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      terraformls = {
        root_markers = { ".git" },
        on_attach = function(client)
          client.server_capabilities.semanticTokensProvider = nil
        end,
      },
      tflint = {
        enabled = false,
      },
    },
  },
}
