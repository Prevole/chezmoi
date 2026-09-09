function azl() {
  az logout
  az login
}

function tgclean() {
  find . -type d -name ".terraform" -prune -exec rm -rf {} \;  ; find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \; ; find . -type f -name ".terraform.lock.hcl" -prune -exec rm -rf {} \;
}

function terra_version() {
  local org="migrosonline"
  local prefix="terra-"
  local name=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --gcp)
        prefix="terra-gcp-module-"
        shift
        ;;
      --name)
        name="$2"
        shift 2
        ;;
      --org)
        org="$2"
        shift 2
        ;;
      --prefix)
        prefix="$2"
        shift 2
        ;;
      -h|--help)
        echo "Usage: terra_version [--gcp] [--name <name>] [--org <org>] [--prefix <prefix>]"
        return 0
        ;;
      *)
        echo "Unknown option: $1"
        return 1
        ;;
    esac
  done

  if ! command -v gh >/dev/null 2>&1; then
    echo "gh is required"
    return 1
  fi

  local repo tag
  printf '%-45s %s\n' "Repository" "Latest tag"
  printf '%-45s %s\n' "----------" "----------"

  gh repo list "$org" --limit 1000 --json name,isArchived \
    --jq ".[] | select(.name | startswith(\"${prefix}\")) | select(.isArchived == false) | .name" |
    sort |
    while IFS= read -r repo; do
      [[ -n "$repo" ]] || continue
      [[ -z "$name" || "$repo" == "${prefix}${name}" || "$repo" == *"-${name}" ]] || continue
      tag=$(gh api graphql \
        -f owner="$org" \
        -f name="$repo" \
        -f query='query($owner:String!, $name:String!) { repository(owner:$owner, name:$name) { refs(refPrefix:"refs/tags/", first:1, orderBy:{field:TAG_COMMIT_DATE, direction:DESC}) { nodes { name } } } }' \
        --jq '.data.repository.refs.nodes[0].name // ""') || return 1
      printf '%-45s %s\n' "$repo" "${tag:-no-tags}"
    done
}

function tv() {
  terra_version "$@"
}

function tvgcp() {
  terra_version --gcp "$@"
}
