#compdef rep orep
#autoloads

local curcontext="$curcontext" state repos line base_repo eligible_repo available_repos eligible_repos scm_dir ret=1

_arguments \
  '1: :->repos' && ret=0

case $state in
	repos)
		if [ "$REPOS_BASEDIRS" ]; then
			available_repos=()
			for base_repo in $(echo "$REPOS_BASEDIRS" | tr ":" "\n"); do
				if [ -d $base_repo ]; then
					eligible_repos=($(ls $base_repo | grep -i "$line[1]"))
					for eligible_repo in "${eligible_repos[@]}"; do
						for scm_dir in $( echo "$REPOS_ELIGIBLE_FILTERS" | tr ":" "\n"); do
							if [ -d "$base_repo/$eligible_repo/$scm_dir" ]; then
								available_repos=( ${available_repos[@]} ${eligible_repo})
								break
							fi
						done
					done
#					array_result=( ${array_result[@]} ${$(ls $repo | grep -i "$line[1]")[@]})
				fi
			done

			if [ ${#available_repos[@]} -gt 0 ]; then 
				_values -S , 'repos' $(echo $available_repos) && ret=0
			else
				ret=0
			fi
		else
			return 1
		fi
		;;
esac

return ret
