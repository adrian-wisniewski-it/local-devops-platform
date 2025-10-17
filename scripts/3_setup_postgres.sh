#!/bin/bash
set -e

export KUBECONFIG=/var/snap/microk8s/current/credentials/client.config

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo privileges. Please run 'sudo ./3_setup_postgres.sh'"
    exit 1
fi

echo "--------------------------------------"
echo "----------------PART 3----------------"
echo "--------------------------------------"

# Ensure Helm is installed
if ! command -v helm &> /dev/null; then
    echo "Helm is not installed. Please run 'sudo ./2_setup_helm.sh' first."
    exit 1
fi

# Check if .db_credentials file exists
if [ ! -f ".db_credentials" ]; then
    echo ".db_credentials file not found. Please run 'sudo ./2_setup_helm.sh' first to create it."
    exit 1
fi

# Load database credentials from .db_credentials file
source .db_credentials
echo "Loaded database credentials from .db_credentials file."

POSTGRES_RELEASE="postgresql-${ENVIRONMENT}"
POSTGRES_NAMESPACE="default"

echo "--------------------------------------"

# Install PostgreSQL using Helm if not already installed
if helm list -n "$POSTGRES_NAMESPACE" -q | grep -q "^${POSTGRES_RELEASE}$"; then
    echo "PostgreSQL release $POSTGRES_RELEASE already exists in namespace $POSTGRES_NAMESPACE. Skipping installation."
else
    echo "Installing PostgreSQL in namespace $POSTGRES_NAMESPACE..."
    helm install "$POSTGRES_RELEASE" bitnami/postgresql \
        --namespace "$POSTGRES_NAMESPACE" \
        --set global.postgresql.auth.username="$DB_USER" \
        --set global.postgresql.auth.password="$DB_PASS" \
        --set global.postgresql.auth.database="localdevopsplatform" \
        --set primary.persistence.size="1Gi" \
        --set primary.resources.requests.cpu="100m" \
        --set primary.resources.requests.memory="128Mi"
    echo "PostgreSQL installed successfully."
fi

echo "--------------------------------------"

# Wait for PostgreSQL pod to be ready
echo "Waiting for PostgreSQL pod to be ready..."
microk8s kubectl wait \
  --namespace "$POSTGRES_NAMESPACE" \
  --for=condition=ready pod \
  -l app.kubernetes.io/name=postgresql \
  --timeout=180s || echo "PostgreSQL pod readiness check timed out."

echo "--------------------------------------"

# Initialize database schema if init.sql file exists
if [ -f "./app/init.sql" ]; then
    echo "Initializing database schema..."
    POSTGRES_POD=$(microk8s kubectl get pods -n "$POSTGRES_NAMESPACE" \
        -l app.kubernetes.io/name=postgresql,app.kubernetes.io/instance="$POSTGRES_RELEASE" \
        -o jsonpath="{.items[0].metadata.name}")
    if [ -n "$POSTGRES_POD" ]; then
        echo "Found PostgreSQL pod: $POSTGRES_POD"
        microk8s kubectl cp ./app/init.sql "$POSTGRES_NAMESPACE/$POSTGRES_POD:/tmp/init.sql"
        microk8s kubectl exec -n "$POSTGRES_NAMESPACE" "$POSTGRES_POD" -- \
            bash -c "PGPASSWORD='$DB_PASS' psql -U '$DB_USER' -d localdevopsplatform -f /tmp/init.sql"
        echo "Database schema initialized."
    else
        echo "Could not find PostgreSQL pod. Skipping schema initialization."
    fi
else
    echo "No init.sql file found. Skipping database schema initialization."    
fi

echo "--------------------------------------"

# Create Kubernetes secret for database credentials
echo "Creating secret for database credentials..."
microk8s kubectl create secret generic "localdevopsplatform-${ENVIRONMENT}-secret" \
  --from-literal=DB_USER="$DB_USER" \
  --from-literal=DB_PASS="$DB_PASS" \
  --namespace "$POSTGRES_NAMESPACE" \
  --dry-run=client -o yaml | microk8s kubectl apply -f -
echo "Secret for database credentials created successfully."

echo "--------------------------------------"
echo "PostgreSQL setup complete."
echo "You can access PostgreSQL at: ${POSTGRES_RELEASE}.${POSTGRES_NAMESPACE}.svc.cluster.local"
echo "--------------------------------------"