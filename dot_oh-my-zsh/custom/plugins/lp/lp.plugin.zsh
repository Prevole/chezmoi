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
# gclone — git clone with automatic SSH host selection
#
# Usage: gclone <org>/<repo> [target-dir]
#        gclone <org>/<repo>.git [target-dir]
#
# The SSH host is chosen based on the current working directory and the
# active chezmoi profile (read from ~/.config/chezmoi/chezmoi.yaml).
# The repository root is read from ~/.config/gitrepos/config.yaml (git.root).
#
#   CWD under <git_root>/work/  → git@github.com
#   CWD under <git_root>/perso/ → git@github-perso (profile=work)
#                               → git@github.com   (profile=lp/sp)
#   Anywhere else               → git@github.com
# ---------------------------------------------------------------------------

function _lp_git_root() {
  local config="$HOME/.config/gitrepos/config.yaml"
  local root
  if [[ -f "$config" ]]; then
    root=$(awk '/^git:/{in_git=1} in_git && /root:/{print $2; exit}' "$config")
  fi
  # Expand ~ and fall back to default
  root="${root:-~/Documents/repositories}"
  echo "${root/#\~/$HOME}"
}

function _lp_chezmoi_profile() {
  local config="$HOME/.config/chezmoi/chezmoi.yaml"
  if [[ -f "$config" ]]; then
    # Extract profile: value from YAML (no dep on yq/python)
    awk '/^data:/{in_data=1} in_data && /profile:/{print $2; exit}' "$config"
  fi
}

function _lp_git_host() {
  local cwd="${1:-$PWD}"
  local profile
  profile="$(_lp_chezmoi_profile)"

  local repos_root
  repos_root="$(_lp_git_root)"

  if [[ "$cwd" == "${repos_root}/work"* ]]; then
    echo "github.com"
  elif [[ "$cwd" == "${repos_root}/perso"* ]]; then
    if [[ "$profile" == "work" ]]; then
      echo "github-perso"
    else
      echo "github.com"
    fi
  else
    echo "github.com"
  fi
}

function gclone() {
  if [[ -z "$1" ]]; then
    echo "Usage: gclone <org>/<repo>[.git] [target-dir]"
    return 1
  fi

  local spec="$1"
  local target="$2"

  # Strip trailing .git if present, then re-add for consistency
  spec="${spec%.git}"

  local host
  host="$(_lp_git_host "$PWD")"

  local url="git@${host}:${spec}.git"

  # Determine the local directory name git will use
  local dest
  if [[ -n "$target" ]]; then
    dest="$target"
  else
    dest="${spec:t}"  # last component of org/repo, without .git
  fi

  echo "Cloning: $url"
  if git clone "$url" ${target:+"$target"}; then
    cd "$dest"
  fi
}

# ---------------------------------------------------------------------------
# repd — navigate to a repository root directory
# ---------------------------------------------------------------------------

function repd() {
  local -a rootdirs
  rootdirs=("${(@f)$(_lp_build_rootdirs_cache)}")
  rootdirs=("${(@u)rootdirs[@]}")
  rootdirs=("${rootdirs[@]:#}")  # remove empty entries

  local query="$1"
  local -a matches

  for rootdir in "${rootdirs[@]}"; do
    [[ -d "$rootdir" ]] || continue
    [[ -z "$query" || "${rootdir:t:l}" == ${query:l}* ]] || continue
    matches+=("$rootdir")
  done

  if [[ ${#matches[@]} -eq 0 ]]; then
    echo "No root directory matching '$query' found."
    return 1
  elif [[ ${#matches[@]} -eq 1 ]]; then
    cd "${matches[1]}"
  else
    local chosen
    chosen=$(printf '%s\n' "${matches[@]}" | fzf --prompt="Select root: " --height=10)
    [[ -z "$chosen" ]] && return 0
    cd "$chosen"
  fi
}

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

# lrep — like rep, but scoped to the current git store directory.
# Finds the deepest known rootdir that contains $PWD, then filters
# candidates to only those under that rootdir.
function lrep() {
  local query="$1"
  local cwd="$PWD"

  # Find the deepest rootdir that is a prefix of CWD
  local -a rootdirs
  rootdirs=("${(@f)$(_lp_build_rootdirs_cache)}")
  rootdirs=("${rootdirs[@]:#}")

  local local_root=""
  local rootdir
  for rootdir in "${rootdirs[@]}"; do
    [[ -z "$rootdir" || ! -d "$rootdir" ]] && continue
    # CWD must be inside this rootdir (or be the rootdir itself)
    [[ "$cwd" == "$rootdir" || "$cwd" == "$rootdir/"* ]] || continue
    # Keep the deepest match
    [[ ${#rootdir} -gt ${#local_root} ]] && local_root="$rootdir"
  done

  if [[ -z "$local_root" ]]; then
    echo "lrep: not inside a known repository store. Use 'rep' instead."
    return 1
  fi

  # Search directly within local_root only (level 1 + level 2)
  local -a matches
  local candidate category

  # Level 1: local_root/repo_name
  for candidate in "$local_root"/*/; do
    candidate="${candidate%/}"
    [[ "${candidate:t:l}" == ${query:l}* ]] || continue
    [[ -d "$candidate/.git" ]] || continue
    matches+=("$candidate")
  done

  # Level 2: local_root/category/repo_name
  for category in "$local_root"/*/; do
    category="${category%/}"
    [[ ! -d "$category" ]] && continue
    [[ -d "$category/.git" ]] && continue
    for candidate in "$category"/*/(N); do
      candidate="${candidate%/}"
      [[ "${candidate:t:l}" == ${query:l}* ]] || continue
      [[ -d "$candidate/.git" ]] || continue
      matches+=("$candidate")
    done
  done

  matches=("${(@u)matches}")

  if [[ ${#matches[@]} -eq 0 ]]; then
    local label="${local_root:t}"
    echo "Repository '${query}' not found in '$label'."
    return 1
  elif [[ ${#matches[@]} -eq 1 ]]; then
    cd "${matches[1]}"
  else
    local chosen
    chosen=$(printf '%s\n' "${matches[@]}" | fzf --prompt="Multiple matches for '${query}' in '${local_root:t}': " --height=10)
    [[ -z "$chosen" ]] && return 0
    cd "$chosen"
  fi
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
