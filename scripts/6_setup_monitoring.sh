#!/bin/bash
set -e

export KUBECONFIG=/var/snap/microk8s/current/credentials/client.config

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo privileges. Please run 'sudo ./6_setup_monitoring.sh'"
    exit 1
fi

echo "--------------------------------------"
echo "----------------PART 6----------------"
echo "--------------------------------------"

# Ensure Helm is installed
if ! command -v helm &> /dev/null; then
    echo "Helm is not installed. Please run 'sudo ./2_setup_helm.sh' first."
    exit 1
fi

MONITORING_NAMESPACE="monitoring"
KUBE_PROM_STACK_RELEASE="kube-prometheus-stack"
LOKI_STACK_RELEASE="loki-stack"

# Create monitoring namespace if it doesn't exist
if ! microk8s kubectl get namespace "$MONITORING_NAMESPACE" &> /dev/null; then
    echo "Creating namespace $MONITORING_NAMESPACE..."
    microk8s kubectl create namespace "$MONITORING_NAMESPACE"
    echo "Namespace $MONITORING_NAMESPACE created."
else
    echo "Namespace $MONITORING_NAMESPACE already exists. Skipping creation."
fi

echo "--------------------------------------"

# Install kube-prometheus-stack using Helm if not already installed
if helm list -n "$MONITORING_NAMESPACE" -q | grep -q "^${KUBE_PROM_STACK_RELEASE}$"; then
    echo "kube-prometheus-stack release $KUBE_PROM_STACK_RELEASE already exists in namespace $MONITORING_NAMESPACE. Skipping installation."
else
    echo "Installing kube-prometheus-stack in namespace $MONITORING_NAMESPACE..."
    helm install "$KUBE_PROM_STACK_RELEASE" prometheus-community/kube-prometheus-stack \
        --namespace "$MONITORING_NAMESPACE" \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
    echo "kube-prometheus-stack installed successfully."
fi

echo "--------------------------------------"

# Install loki-stack using Helm if not already installed
if helm list -n "$MONITORING_NAMESPACE" -q | grep -q "^${LOKI_STACK_RELEASE}$"; then
    echo "loki-stack release $LOKI_STACK_RELEASE already exists in namespace $MONITORING_NAMESPACE. Skipping installation."
else
    echo "Installing loki-stack in namespace $MONITORING_NAMESPACE..."
    helm install "$LOKI_STACK_RELEASE" grafana/loki-stack \
        --namespace "$MONITORING_NAMESPACE" \
        --set promtail.enabled=true \
        --set loki.persistence.enabled=false
    echo "loki-stack installed successfully."
fi

echo "--------------------------------------"

# Wait for Prometheus and Grafana pods to be ready
echo "Waiting for Prometheus and Grafana pods to be ready..."
microk8s kubectl wait \
    --namespace "$MONITORING_NAMESPACE" \
    --for=condition=ready pod \
    -l app.kubernetes.io/name=prometheus \
    --timeout=300s || echo "Prometheus pod readiness check timed out."

microk8s kubectl wait \
    --namespace "$MONITORING_NAMESPACE" \
    --for=condition=ready pod \
    -l app.kubernetes.io/name=grafana \
    --timeout=300s || echo "Grafana pod readiness check timed out."

echo "--------------------------------------"

# Apply monitoring ingress manifest
echo "Applying monitoring ingress manifest..."
microk8s kubectl apply -f monitoring/ingress.yaml
echo "Monitoring ingress applied successfully."

# Apply ServiceMonitor manifest
echo "Applying ServiceMonitor manifest..."
microk8s kubectl apply -f monitoring/servicemonitor.yaml
echo "ServiceMonitor applied successfully."

echo "--------------------------------------"
echo "Monitoring setup complete."
echo "You can access Grafana at: http://grafana.local:8000"
echo "You can access Prometheus at: http://prometheus.local:8000"
echo "--------------------------------------"