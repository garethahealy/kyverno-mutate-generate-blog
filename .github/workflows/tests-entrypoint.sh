#!/usr/bin/env bash

kubectl cluster-info || return $?
test/deploy-kyverno.sh deploy_kyverno
test/deploy-kyverno.sh deploy_policy

# Currently, no way to know if a policy has been accepted by the controller.
# Future: https://docs.google.com/document/d/1Y7_7ow4DgCLyCFQcFVz1vHclghazAKZyolIfprtNURc/edit#heading=h.zcvgnccy18ar
sleep 10s

echo ""
echo "Starting: kyverno tests..."
exec bats test/kyverno-integrationtests.sh