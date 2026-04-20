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
