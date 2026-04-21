function azl() {
  az logout
  az login
}

function tgclean() {
  find . -type d -name ".terraform" -prune -exec rm -rf {} \;  ; find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \; ; find . -type f -name ".terraform.lock.hcl" -prune -exec rm -rf {} \;
}
