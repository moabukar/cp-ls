#!/bin/bash

set -euo pipefail

CLUSTER_NAME=crossplane-localstack-lab
NAMESPACE=crossplane-system
LOCALSTACK_URL="http://localstack.${NAMESPACE}.svc.cluster.local:4566"

log() {
  echo -e "\033[1;32m[+] $1\033[0m"
}

error_exit() {
  echo -e "\033[1;31m[✗] $1\033[0m" >&2
  exit 1
}

check_bin() {
  command -v "$1" >/dev/null 2>&1 || error_exit "'$1' not found. Please install it."
}

log "Checking required CLIs..."
check_bin kind
check_bin kubectl
check_bin helm

log "Creating kind cluster '${CLUSTER_NAME}' (if needed)..."
if ! kind get clusters | grep -q "$CLUSTER_NAME"; then
  kind create cluster --name "$CLUSTER_NAME" || error_exit "Failed to create kind cluster."
else
  log "Cluster already exists. Skipping creation."
fi

log "Installing Crossplane into namespace '${NAMESPACE}'..."
kubectl create namespace "$NAMESPACE" 2>/dev/null || true
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm upgrade --install crossplane crossplane-stable/crossplane -n "$NAMESPACE" || error_exit "Failed to install Crossplane."

log "Installing LocalStack via Helm..."
helm upgrade --install localstack localstack-repo/localstack \
  -n "$NAMESPACE" \
  -f manifests/localstack-values.yaml || error_exit "Failed to install LocalStack."

log "Waiting for LocalStack to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=localstack -n "$NAMESPACE" --timeout=120s || error_exit "LocalStack pod not ready."

log "Applying secrets and providers..."
kubectl apply -f manifests/secret.yml || error_exit "Failed to apply secret."
kubectl apply -f manifests/provider-aws-s3.yml || error_exit "Failed to apply AWS S3 provider."
kubectl apply -f manifests/provider-aws-sqs.yml || error_exit "Failed to apply AWS SQS provider."
kubectl apply -f manifests/provider-aws-ec2.yml || error_exit "Failed to apply AWS EC2 provider."
log "Waiting for providers to become healthy..."
kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-aws-s3 --timeout=90s || error_exit "S3 provider not healthy."
kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-aws-sqs --timeout=90s || error_exit "SQS provider not healthy."

log "Applying ProviderConfig and resources..."
kubectl apply -f manifests/providerconfig.yml || error_exit "Failed to apply ProviderConfig."
kubectl apply -f manifests/s3-bucket.yml || error_exit "Failed to create S3 bucket."
kubectl apply -f manifests/sqs-queue.yml || error_exit "Failed to create SQS queue."
kubectl apply -f manifests/ec2.yml || error_exit "Failed to create EC2 instance."
log "✅ Done. Crossplane + LocalStack are running in-cluster."
echo "→ ProviderConfig uses: ${LOCALSTACK_URL}"
echo "→ Use kubectl get bucket / queue to verify resources"
