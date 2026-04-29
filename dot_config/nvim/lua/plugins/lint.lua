-- Override nvim-lint linters for Terraform:
-- terraform_validate is disabled because it runs `terraform validate` as an
-- external process on every file open, which blocks on network calls to resolve
-- private GitHub modules. terraform-ls already handles validation via LSP.
return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      terraform = {},
      tf = {},
    },
  },
}
