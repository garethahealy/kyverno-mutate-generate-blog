#!/usr/bin/env bats

load bats-support-clone
load test_helper/bats-support/load
load test_helper/redhatcop-bats-library/load

setup_file() {
  oc api-versions --request-timeout=5s || return $?
  oc cluster-info || return $?

  export project_name="kyverno-undertest-$(date +'%d%m%Y-%H%M%S')"

  rm -rf /tmp/rhcop
  oc process --local -f test/resources/namespace-under-test.yml -p=PROJECT_NAME=${project_name} | oc create -f -
}

teardown_file() {
  if [[ -n ${project_name} ]]; then
    oc delete namespace/${project_name}
  fi
}

teardown() {
  if [[ -n "${tmp}" ]]; then
    oc delete -f "${tmp}/list.yml" --ignore-not-found=true --wait=true > /dev/null 2>&1
  fi
}

@test "policy/generate/deny-all-traffic" {
  tmp=$(split_files "policy/generate/deny-all-traffic/test_data/unit")

  cmd="oc create -f ${tmp}/list.yml"
  run ${cmd}

  print_info "${status}" "${output}" "${cmd}" "${tmp}"
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == "namespace/kyverno-undertest-denyalltraffic created" ]]
  [[ "${#lines[@]}" -eq 1 ]]

  # Sometimes the NetworkPolicy might not have been created straight away so we hit a race-condition so we need to try/wait for 10seconds
  count=0
  until oc get NetworkPolicy/deny-all-traffic -o name -n kyverno-undertest-denyalltraffic || (( count++ >= 10 )); do sleep 1s; done

  policyname_missing=$(oc get NetworkPolicy/deny-all-traffic --ignore-not-found=true -o name -n ${project_name})
  policyname_exists=$(oc get NetworkPolicy/deny-all-traffic -o name -n kyverno-undertest-denyalltraffic)

  [[ "${policyname_missing}" == "" ]]
  [[ "${policyname_exists}" == "networkpolicy.networking.k8s.io/deny-all-traffic" ]]
}

@test "policy/mutate/insert-monitoring-container" {
  tmp=$(split_files "policy/mutate/insert-monitoring-container/test_data/unit")

  cmd="oc create -f ${tmp} -n ${project_name}"
  run ${cmd}

  print_info "${status}" "${output}" "${cmd}" "${tmp}"
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == "deployment.apps/signedimage created" ]]
  [[ "${#lines[@]}" -eq 1 ]]

  oc rollout status deployment.apps/signedimage --watch=true --timeout=2m -n ${project_name}

  container_zero=$(oc get pod -l app.kubernetes.io/name=Foo -n ${project_name} -o jsonpath="{.items[0].spec.containers[0].name}")
  container_one=$(oc get pod -l app.kubernetes.io/name=Foo -n ${project_name} -o jsonpath="{.items[0].spec.containers[1].name}")

  [[ "${container_zero}" == "foo" ]]
  [[ "${container_one}" == "pod-monitoring" ]]
}
