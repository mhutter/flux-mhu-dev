#!/usr/bin/env bash
set -e -u -o pipefail

export TILLER_NAMESPACE=helm
export FLUX_FORWARD_NAMESPACE=flux
GIT_REPO='git@github.com:mhutter/flux-mhu-dev.git'

#
# Deploy Helm
#
kubectl apply -f ./helm/
helm init \
  --upgrade \
  --tiller-namespace "$TILLER_NAMESPACE" \
  --service-account tiller \
  --override 'spec.template.spec.containers[0].command'='{/tiller,--storage=secret}' \
  --history-max 10 \
  --wait

#
# Deploy Flux
#
helm repo add fluxcd https://charts.fluxcd.io
helm repo update
helm install fluxcd/flux \
  --name flux \
  --set helmOperator.create=true \
  --set helmOperator.tillerNamespace="$TILLER_NAMESPACE" \
  --set git.url="$GIT_REPO" \
  --namespace "$FLUX_FORWARD_NAMESPACE" \
  --wait

if hash fluxctl 2>/dev/null; then
    fluxctl identity
fi
