# Function to add new files
function rep() {
  _internal_rep "$1" "cd"
}

function orep() {
	_internal_rep "$1" "open"
}

_internal_rep() {
	local base_repo scm_dir

	if [ "$REPOS_BASEDIRS" ]; then
		for base_repo in $(echo "$REPOS_BASEDIRS" | tr ":" "\n"); do
			for scm_dir in $( echo "$REPOS_ELIGIBLE_FILTERS" | tr ":" "\n"); do
				if [ -d "$base_repo/$1/$scm_dir" ]; then
					if [ "$2" = "open" ]; then
						open "$base_repo/$1"
					else
						cd "$base_repo/$1"
					fi
					return 0
				fi
			done
		done
	fi

	echo "Repository $1 not found in ($(echo $REPOS_BASEDIRS | sed 's/:/, /'))"
}

function fg () {
  find . -name "$2" -exec grep -H "$1" {} \;
}

function eprof() {
  vim ~/.zshrc
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
  find . ! -path . -type d -maxdepth 1 -exec sh -c "echo \"Pull repo: {}\" | sed -E 's/\.\///g'; git -C {} s; echo \"#############################################\";" \;
}

function epass() {
  idea ~/.ansible/secrets/all_$1.yaml
}

function epass_switch() {
  sudo rm -f /etc/ansible/group_vars/all
  sudo ln -s /Users/prevole/.ansible/secrets/all_$1.yaml /etc/ansible/group_vars/all
}

function which_space() {
  cat /etc/ansible/group_vars/all | yq ".space" | tr '[:lower:]' '[:upper:]'
}

function azl() {
  az logout
  az login
}

function kcl() {
  while getopts ":r:c:" flag; do
    echo "Flag: $flag"

    case "${flag}" in
      r) REGION=$(echo -n "${OPTARG}" | tr '[:upper:]' '[:lower:]');;
      c) CLUSTER=$(echo -n "${OPTARG}" | tr '[:upper:]' '[:lower:]');;
    esac
  done
  
  echo "Region: $REGION"
  echo "Cluster: $CLUSTER"

  if [[ -z "${REGION}" ]]; then
    REGION="swn"
  fi

  if [[ -z "${CLUSTER}" ]]; then
    CLUSTER="apps"
  fi

  ENV_RG=$(echo -n "${@:$OPTIND:1}" | tr '[:upper:]' '[:lower:]')
  ENV_NAME=$(echo -n "${@:$OPTIND:1}" | tr '[:lower:]' '[:upper:]')

  AKS="mo-${REGION}-${ENV_RG}-${CLUSTER}"

  echo "Log in to ${ENV_NAME} - ${AKS}"

  az account set --subscription "MO-${ENV_NAME}"
  az aks get-credentials --resource-group "${AKS}-rg" --name "${AKS}-aks"

  echo "Connected"
}

function acrl() {
  az acr login -n moswncoremainregistrycr
}

function tgclean() {
  find . -type d -name ".terraform" -prune -exec rm -rf {} \;  ; find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \; ; find . -type f -name ".terraform.lock.hcl" -prune -exec rm -rf {} \;
}

function update() {
  echo "Updating..."

  echo "Updatating oh-my-zsh..."
  omz update

  echo "Updating brew..."
  brew update
  brew upgrade
  brew cleanup
}
