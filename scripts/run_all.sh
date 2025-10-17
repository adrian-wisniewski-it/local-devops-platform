#!/bin/bash
set -e

export KUBECONFIG=/var/snap/microk8s/current/credentials/client.config


if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo privileges. Please run 'sudo ./run_all.sh'"
    exit 1
fi

# Check if we're in the correct directory (local-devops-platform)
if [ ! -d "scripts" ] || [ ! -f "scripts/1_setup_environment.sh" ]; then
    echo "Error: This script must be run from the local-devops-platform directory."
    echo "Please cd to the project root directory first."
    exit 1
fi

echo "--------------------------------------"
echo "Running full platform setup..."
echo "--------------------------------------"

bash scripts/1_setup_environment.sh
bash scripts/2_setup_helm.sh
bash scripts/3_setup_postgres.sh
bash scripts/4_setup_jenkins.sh
bash scripts/5_setup_argocd.sh
bash scripts/6_setup_monitoring.sh

echo "--------------------------------------"
echo "All components installed successfully."
echo "--------------------------------------"
echo ""
echo "Application URL: http://localdevopsplatform.local:8000"
echo "Jenkins URL: http://localhost:8080"
echo "ArgoCD URL: http://argocd.local:8000"
echo "Grafana URL: http://grafana.local:8000"
echo "Prometheus URL: http://prometheus.local:8000"
echo ""
echo "Credentials:"
if [ -f ".db_credentials" ]; then
    source .db_credentials
    echo "  PostgreSQL Username: $DB_USER"
    echo "  PostgreSQL Password: $DB_PASS"
fi
echo "  Jenkins: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo "  ArgoCD: microk8s kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d && echo"
echo "  Grafana: microk8s kubectl get secret kube-prometheus-stack-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d && echo"
echo ""

# Cleanup credentials file
if [ -f ".db_credentials" ]; then
    shred -u .db_credentials
    echo "Temporary credentials file securely deleted."
fi

echo "--------------------------------------"