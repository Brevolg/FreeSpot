#!/usr/bin/env bash
set -euo pipefail
: "${KUBECONFIG:?Set KUBECONFIG to the team-3 kubeconfig path}"
: "${IMAGE_TAG:?Set IMAGE_TAG to the published immutable release tag}"
cd "$(dirname "$0")/../.."
case "$(helm version --template '{{.Version}}')" in
  v3.*) rollback_flags=(--atomic --wait) ;;
  v4.*) rollback_flags=(--rollback-on-failure --wait=legacy) ;;
  *) echo "Helm 3 or 4 required" >&2; exit 1 ;;
esac
python3 deploy/k8s/bootstrap-secrets.py
helm upgrade --install freespot deploy/helm/freespot \
  --namespace team-3 \
  --set-string "backend.tag=$IMAGE_TAG" \
  --set-string "frontend.tag=$IMAGE_TAG" \
  "${rollback_flags[@]}" --timeout 5m "$@"
kubectl --namespace team-3 get pods,ingress,pvc -l app.kubernetes.io/part-of=freespot
