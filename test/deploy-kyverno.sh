#!/usr/bin/env bash

command -v oc &> /dev/null || { echo >&2 'ERROR: oc not installed - Aborting'; exit 1; }

deploy_kyverno() {
  echo ""
  echo "Collecting control-plane related namespaces..."

  excludedNamespaces=()
  for namespace in $(oc get namespaces -o jsonpath='{.items[*].metadata.name}' | xargs); do
    if [[ "${namespace}" =~ openshift.* ]] || [[ "${namespace}" =~ kube.* ]] || [[ "${namespace}" =~ default ]]; then
      excludedNamespaces+=("[*,${namespace},*]")
    fi
  done

  local excludedNamespacesList
  excludedNamespacesList=$(echo "${excludedNamespaces[@]}" | tr -d "[:space:]")

  local defaultResourceFilters="[Event,*,*][Node,*,*][APIService,*,*][TokenReview,*,*][SubjectAccessReview,*,*][SelfSubjectAccessReview,*,*][Binding,*,*][ReplicaSet,*,*][ReportChangeRequest,*,*][ClusterReportChangeRequest,*,*][*,kyverno,*]"
  local resourceFilters=$(echo "${defaultResourceFilters}${excludedNamespacesList}" | sed 's/,/\\,/g')

  echo ""
  echo "Deploying kyverno..."
  helm repo add kyverno https://kyverno.github.io/kyverno
  helm repo update

  helm install kyverno kyverno/kyverno --namespace kyverno --create-namespace --set=replicaCount=3,podSecurityStandard=custom,config.resourceFilters="$resourceFilters"

  echo ""
  echo "Waiting for kyverno to be ready..."
  oc rollout status Deployment/kyverno -n kyverno --watch=true
}

deploy_policy() {
  echo ""
  echo "Deploying policies..."

  # shellcheck disable=SC2038
  for file in $(find policy/* -name "src.yaml" -type f | xargs); do
    name=$(oc create -f "${file}" -n kyverno -o name || exit $?)
    echo "${name}"
  done
}

# Process arguments
case $1 in
  deploy_kyverno)
    command -v helm &> /dev/null || { echo >&2 'ERROR: helm not installed - Aborting'; exit 1; }
    deploy_kyverno
    ;;
  deploy_policy)
    deploy_policy
    ;;
  *)
    echo "Not an option"
    exit 1
esac
