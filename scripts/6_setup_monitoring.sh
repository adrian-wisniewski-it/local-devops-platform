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
LOKI_RELEASE="loki"
PROMTAIL_RELEASE="promtail"

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
    echo "kube-prometheus-stack already installed. Skipping."
else
    echo "Installing kube-prometheus-stack..."
    helm install "$KUBE_PROM_STACK_RELEASE" prometheus-community/kube-prometheus-stack \
        --namespace "$MONITORING_NAMESPACE" \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
    echo "kube-prometheus-stack installed."
fi

echo "--------------------------------------"

# Install Loki using Helm if not already installed
if helm list -n "$MONITORING_NAMESPACE" -q | grep -q "^${LOKI_RELEASE}$"; then
    echo "Loki already installed. Skipping."
else
    echo "Installing Loki..."
    helm install "$LOKI_RELEASE" grafana/loki \
        --namespace "$MONITORING_NAMESPACE" \
        --set deploymentMode=SingleBinary \
        --set loki.auth_enabled=false \
        --set loki.commonConfig.replication_factor=1 \
        --set loki.storage.type=filesystem \
        --set loki.useTestSchema=true \
        --set singleBinary.replicas=1 \
        --set write.replicas=0 \
        --set read.replicas=0 \
        --set backend.replicas=0 \
        --set chunksCache.enabled=false \
        --set resultsCache.enabled=false
    echo "Loki installed."
fi

echo "--------------------------------------"

# Install Promtail using Helm if not already installed
if helm list -n "$MONITORING_NAMESPACE" -q | grep -q "^${PROMTAIL_RELEASE}$"; then
    echo "Promtail already installed. Skipping."
else
    echo "Installing Promtail..."
    helm install "$PROMTAIL_RELEASE" grafana/promtail \
        --namespace "$MONITORING_NAMESPACE" \
        --set "config.clients[0].url=http://loki:3100/loki/api/v1/push"
    echo "Promtail installed."
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

# Apply monitoring infrastructure ingress
echo "Applying monitoring infrastructure ingress..."
microk8s kubectl apply -f kubernetes/monitoring/ingress.yaml
echo "Monitoring infrastructure ingress applied successfully."

echo "--------------------------------------"
echo "Monitoring infrastructure setup complete."
echo "You can access Grafana at: http://grafana.local:8000"
echo "You can access Prometheus at: http://prometheus.local:8000"
echo "You can access Alertmanager at: http://alertmanager.local:8000"
echo "--------------------------------------"