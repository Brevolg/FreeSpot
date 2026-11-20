#!/usr/bin/env bash
set -euo pipefail
: "${KUBECONFIG:?Set KUBECONFIG to the team-3 kubeconfig path}"
: "${IMAGE_TAG:?Set IMAGE_TAG to the published immutable release tag}"
cd "$(dirname "$0")/../.."
python3 deploy/k8s/bootstrap-secrets.py
helm upgrade --install freespot deploy/helm/freespot \
  --namespace team-3 \
  --set-string "backend.tag=$IMAGE_TAG" \
  --set-string "frontend.tag=$IMAGE_TAG" \
  --atomic --wait --timeout 5m "$@"
kubectl --namespace team-3 get pods,ingress,pvc -l app.kubernetes.io/part-of=freespot
