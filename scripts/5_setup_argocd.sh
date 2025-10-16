#!/bin/bash
set -e

export KUBECONFIG=/var/snap/microk8s/current/credentials/client.config

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo privileges. Please run 'sudo ./5_setup_argocd.sh'"
    exit 1
fi

echo "--------------------------------------"
echo "----------------PART 5----------------"
echo "--------------------------------------"

# Ensure Helm is installed
if ! command -v helm &> /dev/null; then
    echo "Helm is not installed. Please run 'sudo ./2_setup_helm.sh' first."
    exit 1
fi

ARGOCD_NAMESPACE="argocd"
ARGOCD_RELEASE="argocd"

# Create argocd namespace if it doesn't exist
if ! microk8s kubectl get namespace "$ARGOCD_NAMESPACE" &> /dev/null; then
    echo "Creating namespace $ARGOCD_NAMESPACE..."
    microk8s kubectl create namespace "$ARGOCD_NAMESPACE"
    echo "Namespace $ARGOCD_NAMESPACE created."
else
    echo "Namespace $ARGOCD_NAMESPACE already exists. Skipping creation."
fi

echo "--------------------------------------"

# Install ArgoCD using Helm if not already installed
if helm list -n "$ARGOCD_NAMESPACE" -q | grep -q "^${ARGOCD_RELEASE}$"; then
    echo "ArgoCD release $ARGOCD_RELEASE already exists in namespace $ARGOCD_NAMESPACE. Skipping installation."
else
    echo "Installing ArgoCD in namespace $ARGOCD_NAMESPACE..."
    read -s -p "Enter ArgoCD admin password: " ARGOCD_PASS
    echo ""
    ARGOCD_PASS_HASH=$(docker run --rm python:3.9-slim python -c "import bcrypt; print(bcrypt.hashpw(b'$ARGOCD_PASS', bcrypt.gensalt()).decode())")
    helm install "$ARGOCD_RELEASE" argo/argo-cd \
        --namespace "$ARGOCD_NAMESPACE" \
        --set server.service.type=ClusterIP \
        --set configs.params."server\.insecure"=true \
        --set configs.secret.argocdServerAdminPassword="$ARGOCD_PASS_HASH"
    echo "ArgoCD installed successfully."
fi

echo "--------------------------------------"

# Wait for ArgoCD server pod to be ready
echo "Waiting for ArgoCD server pod to be ready..."
microk8s kubectl wait \
    --namespace "$ARGOCD_NAMESPACE" \
    --for=condition=ready pod \
    -l app.kubernetes.io/name=argocd-server \
    --timeout=180s || echo "ArgoCD server pod readiness check timed out."

echo "--------------------------------------"

# Apply ingress and application manifests
echo "Applying ingress and application manifests..."
microk8s kubectl apply -f argocd/ingress.yaml
microk8s kubectl apply -f argocd/application.yaml
echo "Manifests applied successfully."

echo "--------------------------------------"
echo "ArgoCD setup complete."
echo "You can access ArgoCD at: http://argocd.local:8000"
echo "--------------------------------------"