#compdef rep orep repnc repd lrep
#autoloads

local -a rootdirs
local rootdir candidate repo_name category
local partial="${PREFIX}"

# repd: complete root directories
if [[ "$service" == "repd" ]]; then
  local -a all_roots root_display

  rootdirs=("${(@f)$(_lp_build_rootdirs_cache)}")
  for rootdir in "${(@u)rootdirs[@]}"; do
    [[ -z "$rootdir" || ! -d "$rootdir" ]] && continue
    local name="${rootdir:t}"
    [[ "${name:l}" == ${partial:l}* ]] || continue
    all_roots+=("$name")
    root_display+=("$name  ($rootdir)")
  done

  [[ ${#all_roots[@]} -gt 0 ]] && compadd -U -Q -d root_display -M 'l:|=* m:{a-z}={A-Z}' -a all_roots
  return
fi

# lrep: complete repos scoped to the current rootdir
if [[ "$service" == "lrep" ]]; then
  local -a all_rootdirs
  all_rootdirs=("${(@f)$(_lp_build_rootdirs_cache)}")

  # Find deepest rootdir containing $PWD
  local local_root="" rdir
  for rdir in "${all_rootdirs[@]}"; do
    [[ -z "$rdir" || ! -d "$rdir" ]] && continue
    [[ "$PWD" == "$rdir" || "$PWD" == "$rdir/"* ]] || continue
    [[ ${#rdir} -gt ${#local_root} ]] && local_root="$rdir"
  done

  [[ -z "$local_root" ]] && return 1

  local -A repo_paths

  # Level 1
  for candidate in "$local_root"/*/; do
    candidate="${candidate%/}"
    repo_name="${candidate:t}"
    [[ "${repo_name:l}" == ${partial:l}* ]] || continue
    [[ -d "$candidate/.git" ]] || continue
    repo_paths[$repo_name]+="${candidate}"$'\n'
  done

  # Level 2
  for category in "$local_root"/*/; do
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

  local -a comp_values comp_display
  for repo_name in "${(@k)repo_paths}"; do
    local -a paths
    paths=("${(@f)${repo_paths[$repo_name]%$'\n'}}")
    paths=("${(@u)paths}")
    comp_values+=("$repo_name")
    if [[ ${#paths[@]} -eq 1 ]]; then
      comp_display+=("$repo_name")
    else
      comp_display+=("${repo_name}  (${#paths[@]} repositories)")
    fi
  done

  [[ ${#comp_values[@]} -gt 0 ]] && compadd -U -Q -d comp_display -M 'l:|=* m:{a-z}={A-Z}' -a comp_values
  return
fi

# Use the shared cache builder from lp.plugin.zsh — single source of truth.
# REP_NO_CACHE is honoured automatically.
rootdirs=("${(@f)$(_lp_build_rootdirs_cache)}")

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

# -U : disable zsh prefix filter (we do our own case-insensitive matching)
# -Q : disable quoting
[[ ${#comp_values[@]} -gt 0 ]] && compadd -U -Q -d comp_display -M 'l:|=* m:{a-z}={A-Z}' -a comp_values
