# Capture plugin directory at load time — $0 is not reliable inside functions
_lp_plugin_dir="${0:A:h}"

# ---------------------------------------------------------------------------
# Cache management — rootdirs extracted from ~/.gitconfig includeIf entries.
# Cache is invalidated when ~/.gitconfig is newer than the cache file.
# ---------------------------------------------------------------------------

_lp_cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/lp/rootdirs"

_lp_build_rootdirs_cache() {
  local cache_file="$_lp_cache_file"
  local gitconfig="$HOME/.gitconfig"

  # Return cached value if still valid (bypass with REP_NO_CACHE=1)
  if [[ -z "${REP_NO_CACHE:-}" && -f "$cache_file" && "$cache_file" -nt "$gitconfig" ]]; then
    cat "$cache_file"
    return
  fi

  # Parse gitdir entries from includeIf blocks
  local -a rootdirs
  local line dir

  while IFS= read -r line; do
    if [[ "$line" =~ 'includeIf "gitdir:(.+)"' ]]; then
      dir="${match[1]}"
      # Expand ~ and strip trailing slash
      dir="${dir/#\~/$HOME}"
      dir="${dir%/}"
      # Always add both the path itself and its parent as rootdirs.
      # This handles two cases:
      #   - gitdir is a container of repos (e.g. ~/Documents/repositories/work/)
      #     → the path itself is the rootdir
      #   - gitdir is a repo directly (e.g. ~/.local/share/chezmoi/)
      #     → the parent is the rootdir
      # _lp_find_repos filters by .git presence so false positives are harmless.
      rootdirs+=("$dir")
      rootdirs+=("${dir:h}")
    fi
  done < "$gitconfig"

  # Deduplicate
  rootdirs=("${(u)rootdirs[@]}")

  # Write cache (skipped when REP_NO_CACHE=1 to avoid polluting with debug runs)
  if [[ -z "${REP_NO_CACHE:-}" ]]; then
    mkdir -p "$(dirname "$cache_file")"
    printf '%s\n' "${rootdirs[@]}" > "$cache_file"
  fi

  printf '%s\n' "${rootdirs[@]}"
}

# Force rebuild the rootdirs cache immediately
function lp_cache_refresh() {
  rep_cc
  _lp_build_rootdirs_cache > /dev/null
  echo "lp: rootdirs cache refreshed."
}

# Clear the rootdirs cache — will be rebuilt on next rep/orep call
function rep_cc() {
  rm -f "$_lp_cache_file"
  echo "lp: rootdirs cache cleared."
}

# rep without cache — useful to debug cache vs plugin issues
alias repnc="REP_NO_CACHE=1 rep"
compdef repnc=rep

# ---------------------------------------------------------------------------
# Repo lookup — level 1 (rootdir/repo_name) then level 2 (rootdir/*/repo_name)
# ---------------------------------------------------------------------------

_lp_find_repos() {
  local query="$1"
  local -a rootdirs matches
  local rootdir candidate

  while IFS= read -r rootdir; do
    [[ -z "$rootdir" ]] && continue

    # Level 1: rootdir/repo_name — case-insensitive prefix match
    for candidate in "$rootdir"/*/; do
      candidate="${candidate%/}"
      [[ "${candidate:t:l}" == ${query:l}* ]] || continue
      [[ -d "$candidate/.git" ]] || continue
      matches+=("$candidate")
    done

    # Level 2: rootdir/category/repo_name — case-insensitive prefix match
    for candidate in "$rootdir"/*/*/(N); do
      candidate="${candidate%/}"
      [[ "${candidate:t:l}" == ${query:l}* ]] || continue
      [[ -d "$candidate/.git" ]] || continue
      matches+=("$candidate")
    done
  done <<< "$(_lp_build_rootdirs_cache)"

  # Deduplicate
  print -l "${(u)matches[@]}"
}

# ---------------------------------------------------------------------------
# rep / orep — navigate or open a repository
# ---------------------------------------------------------------------------

function rep() {
  _internal_rep "$1" "cd"
}

function orep() {
  _internal_rep "$1" "open"
}

_internal_rep() {
  local query="$1"
  local action="$2"
  local -a matches
  local chosen

  matches=("${(@f)$(_lp_find_repos "$query")}")
  matches=("${matches[@]:#}")  # remove empty entries

  if [[ ${#matches[@]} -eq 0 ]]; then
    echo "Repository '$query' not found."
    return 1
  elif [[ ${#matches[@]} -eq 1 ]]; then
    chosen="${matches[1]}"
  else
    chosen=$(printf '%s\n' "${matches[@]}" | fzf --prompt="Multiple matches for '$query': " --height=10)
    [[ -z "$chosen" ]] && return 0
  fi

  if [[ "$action" == "open" ]]; then
    open "$chosen"
  else
    cd "$chosen"
  fi
}

# ---------------------------------------------------------------------------
# Git repository management
# ---------------------------------------------------------------------------

# Clone all repositories from 1Password (Git Repositories - <profile>)
# that are not already present on the filesystem.
# Root directory is read from ~/.config/gitrepos/config.yaml.
function repos_clone() {
  ruby "$_lp_plugin_dir/repos_clone.rb"
}

# Import a YAML file into 1Password (Git Repositories - <profile>),
# replacing the current content entirely.
# The file must have a 'repositories' key (flat list or categorized map).
function repos_track_import() {
  if [[ -z "$1" ]]; then
    echo "Usage: repos_track_import <file.yaml>"
    return 1
  fi

  ruby "$_lp_plugin_dir/repos_track_import.rb" "$1"
}

# Track the current git repository into 1Password (Git Repositories - <profile>).
# Detects flat vs category mode from the directory structure:
#   <root>/<repo>          → flat (parent has no .git, is the root itself)
#   <root>/<category>/<repo> → category mode (parent has no .git, is not the root)
function repo_track() {
  local config_file="$HOME/.config/gitrepos/config.yaml"

  if [[ ! -f "$config_file" ]]; then
    echo "Config file not found: $config_file"
    return 1
  fi

  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$git_root" ]]; then
    echo "Not inside a git repository."
    return 1
  fi

  local repo_root name url category
  repo_root=$(ruby -ryaml -e "puts File.expand_path(YAML.load_file('$config_file')['git']['root'])")
  name=$(basename "$git_root")
  url=$(git -C "$git_root" remote get-url origin 2>/dev/null)

  if [[ -z "$url" ]]; then
    echo "No remote 'origin' found for this repository."
    return 1
  fi

  # Detect flat vs category from directory structure:
  # flat     → parent == repo_root (repo is directly under root)
  # category → parent != repo_root and parent has no .git (parent is a category folder)
  local parent
  parent=$(dirname "$git_root")

  if [[ "$parent" == "$repo_root" ]]; then
    category=""
  else
    category="${parent#$repo_root/}"
  fi

  echo "Repository : $name"
  echo "URL        : $url"
  echo "Root       : $repo_root"
  [[ -n "$category" ]] && echo "Category   : $category"
  echo ""

  ruby "$_lp_plugin_dir/repo_track.rb" "$category" "$name" "$url"
}

# ---------------------------------------------------------------------------
# Utility functions
# ---------------------------------------------------------------------------

function fgg() {
  rg "$1" --glob "$2"
}

function eprof() {
  nvim ~/.zshrc
}

function sprof() {
  source ~/.zshrc
}

function repos_pull() {
  local sep="#############################################"
  echo "$sep"
  for repo in */; do
    [[ -d "${repo%.git}/.git" || -d "$repo.git" ]] || continue
    echo "Pull repo: ${repo%/}"
    git -C "$repo" pull
    echo "$sep"
  done
}

function repos_stat() {
  local sep="#############################################"
  echo "$sep"
  for repo in */; do
    [[ -d "${repo%.git}/.git" || -d "$repo.git" ]] || continue
    echo "Stat repo: ${repo%/}"
    git -C "$repo" s
    echo "$sep"
  done
}

function cedit() {
  $EDITOR "$(chezmoi source-path)/$1"
}

function _cedit() {
  local source_dir
  source_dir="$(chezmoi source-path 2>/dev/null)" || return 1

  local -a files display
  local f name

  for f in "$source_dir"/*(N); do
    name="${f:t}"
    name="${name#dot_}"
    name="${name#executable_}"
    name="${name#private_}"
    name="${name#readonly_}"
    name="${name%.tmpl}"
    name=".${name}"
    files+=("${f:t}")
    display+=("$name")
  done

  compadd -U -Q -d display -a files
}

compdef _cedit cedit

function mega-update() {
  local sep="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  echo "$sep"
  echo "chezmoi"
  echo "$sep"
  chezmoi update

  echo "$sep"
  echo "brew"
  echo "$sep"
  brew update && brew upgrade && brew cleanup

  echo "$sep"
  echo "oh-my-zsh"
  echo "$sep"
  omz update

  echo "$sep"
  echo "mise"
  echo "$sep"
  mise upgrade --yes

  echo "$sep"
  echo "gh extensions"
  echo "$sep"
  gh extension upgrade --all

  echo "$sep"
  echo "mega-update done"
  echo "$sep"
}
