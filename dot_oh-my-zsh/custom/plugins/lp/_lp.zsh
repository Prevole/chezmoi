#compdef rep orep
#autoloads

local curcontext="$curcontext" state ret=1

_arguments \
  '1: :->repos' && ret=0

case $state in
  repos)
    local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/lp/rootdirs"
    local gitconfig="$HOME/.gitconfig"
    local -a rootdirs available_repos
    local -A seen_repos
    local rootdir candidate repo_name partial

    partial="${words[CURRENT]}"

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

    available_repos=()

    for rootdir in "${rootdirs[@]}"; do
      [[ -z "$rootdir" || ! -d "$rootdir" ]] && continue

      # Level 1: rootdir/repo_name
      for candidate in "$rootdir"/*/; do
        candidate="${candidate%/}"
        repo_name="${candidate:t}"
        [[ "$repo_name" != ${partial}* ]] && continue
        if [[ -d "$candidate/.git" ]]; then
          if [[ -n "${seen_repos[$repo_name]}" && "${seen_repos[$repo_name]}" != "shown" ]]; then
            # Upgrade first entry to full path
            available_repos+=("${repo_name}:${seen_repos[$repo_name]}")
            seen_repos[$repo_name]="shown"
          fi
          if [[ "${seen_repos[$repo_name]}" == "shown" ]]; then
            available_repos+=("${repo_name}:${candidate}")
          elif [[ -z "${seen_repos[$repo_name]}" ]]; then
            seen_repos[$repo_name]="$candidate"
            available_repos+=("$repo_name")
          fi
        fi
      done

      # Level 2 (fallback): rootdir/category/repo_name
      for category in "$rootdir"/*/; do
        [[ ! -d "$category" ]] && continue
        for candidate in "$category"/*/; do
          candidate="${candidate%/}"
          repo_name="${candidate:t}"
          [[ "$repo_name" != ${partial}* ]] && continue
          if [[ -d "$candidate/.git" ]]; then
            if [[ -n "${seen_repos[$repo_name]}" && "${seen_repos[$repo_name]}" != "shown" ]]; then
              available_repos+=("${repo_name}:${seen_repos[$repo_name]}")
              seen_repos[$repo_name]="shown"
            fi
            if [[ "${seen_repos[$repo_name]}" == "shown" ]]; then
              available_repos+=("${repo_name}:${candidate}")
            elif [[ -z "${seen_repos[$repo_name]}" ]]; then
              seen_repos[$repo_name]="$candidate"
              available_repos+=("$repo_name")
            fi
          fi
        done
      done
    done

    if [[ ${#available_repos[@]} -gt 0 ]]; then
      compadd -Q -a available_repos && ret=0
    else
      ret=0
    fi
    ;;
esac

return ret
