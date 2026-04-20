# ---------------------------------------------------------------------------
# Cache management — rootdirs extracted from ~/.gitconfig includeIf entries.
# Cache is invalidated when ~/.gitconfig is newer than the cache file.
# ---------------------------------------------------------------------------

_lp_cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/lp/rootdirs"

_lp_build_rootdirs_cache() {
  local cache_file="$_lp_cache_file"
  local gitconfig="$HOME/.gitconfig"

  # Return cached value if still valid
  if [[ -f "$cache_file" && "$cache_file" -nt "$gitconfig" ]]; then
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
      rootdirs+=("$dir")
    fi
  done < "$gitconfig"

  # Write cache
  mkdir -p "$(dirname "$cache_file")"
  printf '%s\n' "${rootdirs[@]}" > "$cache_file"

  printf '%s\n' "${rootdirs[@]}"
}

# Force rebuild the rootdirs cache
function lp_cache_refresh() {
  rm -f "$_lp_cache_file"
  _lp_build_rootdirs_cache > /dev/null
  echo "lp: rootdirs cache refreshed."
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

    # Level 1: rootdir/repo_name/.git
    candidate="$rootdir/$query"
    if [[ -d "$candidate/.git" ]]; then
      matches+=("$candidate")
      continue
    fi

    # Level 2 (fallback): rootdir/*/repo_name/.git
    for candidate in "$rootdir"/*/; do
      candidate="${candidate%/}/$query"
      if [[ -d "$candidate/.git" ]]; then
        matches+=("$candidate")
      fi
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
# Utility functions
# ---------------------------------------------------------------------------

function fg() {
  find . -name "$2" -exec grep -H "$1" {} \;
}

function eprof() {
  nvim ~/.zshrc
}

function sprof() {
  source ~/.zshrc
}

function repos_pull() {
  echo "#############################################"
  find . ! -path . -type d -maxdepth 1 -exec sh -c "echo \"Pull repo: {}\" | sed -E 's/\.\///g'; git -C {} pull; echo \"#############################################\";" \;
}

function repos_stat() {
  echo "#############################################"
  find . ! -path . -type d -maxdepth 1 -exec sh -c "echo \"Stat repo: {}\" | sed -E 's/\.\///g'; git -C {} s; echo \"#############################################\";" \;
}

function update() {
  echo "Updating..."

  echo "Updating oh-my-zsh..."
  omz update

  echo "Updating brew..."
  brew update
  brew upgrade
  brew cleanup
}
