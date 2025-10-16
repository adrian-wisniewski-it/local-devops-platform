#!/bin/bash
set -e

export KUBECONFIG=/var/snap/microk8s/current/credentials/client.config 

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo privileges. Please run 'sudo ./2_setup_helm.sh'"
    exit 1
fi

echo "--------------------------------------"
echo "----------------PART 2----------------"
echo "--------------------------------------"

# Install Helm
echo "Installing Helm..."
if ! command -v helm &> /dev/null; then
    echo "Helm not found. Proceeding with installation."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    bash get_helm.sh
    rm get_helm.sh
    echo "Helm installed successfully."
else
    echo "Helm is already installed. Skipping installation."
fi

echo "--------------------------------------"

# Add Helm repositories
echo "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo add argo https://argoproj.github.io/argo-helm || true
helm repo add bitnami https://charts.bitnami.com/bitnami || true
helm repo update
echo "Helm repositories added successfully."

echo "--------------------------------------"

# Ask for environment type and database credentials
while true; do
    read -p "Choose environment type (dev/prod): " ENV
    if [[ "$ENV" == "dev" || "$ENV" == "prod" ]]; then
        break
    else
        echo "Invalid environment type. Please enter 'dev' or 'prod' to continue."
    fi
done

read -p "Enter database username: " DB_USER
read -s -p "Enter database password: " DB_PASS
echo ""
echo "--------------------------------------"

# Save database credentials to .db_credentials file (used by PostgreSQL setup)
echo "Saving database credentials to .db_credentials file..."
cat <<EOF > .db_credentials
ENVIRONMENT=$ENV
DB_USER=$DB_USER
DB_PASS=$DB_PASS
EOF
chmod 600 .db_credentials
echo "Database credentials saved to .db_credentials file."

echo "--------------------------------------"
echo "Helm setup complete."
echo "--------------------------------------"

