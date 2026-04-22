#compdef rep orep
#autoloads

local curcontext="$curcontext" state ret=1

_arguments \
  '1: :->repos' && ret=0

case $state in
  repos)
    local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/lp/rootdirs"
    local gitconfig="$HOME/.gitconfig"
    local -a rootdirs
    local rootdir candidate repo_name category

    local partial="${PREFIX}"

    # Build rootdirs from cache or parse .gitconfig
    if [[ -f "$cache_file" && "$cache_file" -nt "$gitconfig" ]]; then
      rootdirs=("${(@f)$(cat "$cache_file")}")
    else
      local line dir
      while IFS= read -r line; do
        if [[ "$line" =~ 'includeIf "gitdir:(.+)"' ]]; then
          dir="${match[1]}"
          dir="${dir/#\~/$HOME}"
          dir="${dir%/}"
          rootdirs+=("$dir")
        fi
      done < "$gitconfig"
      mkdir -p "$(dirname "$cache_file")"
      printf '%s\n' "${rootdirs[@]}" > "$cache_file"
    fi

    # Collect all matching paths per repo name (case-insensitive prefix match)
    local -A repo_paths  # repo_name -> newline-separated list of full paths

    for rootdir in "${rootdirs[@]}"; do
      [[ -z "$rootdir" || ! -d "$rootdir" ]] && continue

      # Level 1: rootdir/repo_name
      for candidate in "$rootdir"/*/; do
        candidate="${candidate%/}"
        repo_name="${candidate:t}"
        [[ "${repo_name:l}" == ${partial:l}* ]] || continue
        [[ -d "$candidate/.git" ]] || continue
        repo_paths[$repo_name]+="${candidate}"$'\n'
      done

      # Level 2: rootdir/category/repo_name — skip dirs that are themselves repos
      for category in "$rootdir"/*/; do
        category="${category%/}"
        [[ ! -d "$category" ]] && continue
        [[ -d "$category/.git" ]] && continue
        for candidate in "$category"/*/(N); do
          candidate="${candidate%/}"
          repo_name="${candidate:t}"
          [[ "${repo_name:l}" == ${partial:l}* ]] || continue
          [[ -d "$candidate/.git" ]] || continue
          repo_paths[$repo_name]+="${candidate}"$'\n'
        done
      done
    done

    # Build completion arrays
    # Always insert the repo name — fzf handles disambiguation at runtime
    # -U disables zsh's built-in prefix filtering (we do our own, case-insensitive)
    local -a comp_values comp_display

    for repo_name in "${(@k)repo_paths}"; do
      local -a paths
      paths=("${(@f)${repo_paths[$repo_name]%$'\n'}}")
      paths=("${(@u)paths}")

      if [[ ${#paths[@]} -eq 1 ]]; then
        comp_values+=("$repo_name")
        comp_display+=("$repo_name")
      else
        comp_values+=("$repo_name")
        comp_display+=("${repo_name}  (${#paths[@]} repositories)")
      fi
    done

    if [[ ${#comp_values[@]} -gt 0 ]]; then
      compadd -d comp_display -M 'l:|=* m:{a-z}={A-Z}' -a comp_values && ret=0
    else
      ret=0
    fi
    ;;
esac

return ret
