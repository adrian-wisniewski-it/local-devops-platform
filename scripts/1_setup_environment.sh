#!/bin/bash
set -e

TARGET_USER=${SUDO_USER:-root}

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo privileges. Please run 'sudo ./1_setup_environment.sh'"
    exit 1
fi

echo "--------------------------------------"
echo "----------------PART 1----------------"
echo "--------------------------------------"

# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Proceeding with installation."
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable --now docker
    usermod -aG docker "$TARGET_USER"
    systemctl restart docker
    echo "Docker installed successfully."
else
    echo "Docker is already installed. Skipping installation."
fi

echo "--------------------------------------"

# Install Kubernetes (MicroK8s)
echo "Installing Kubernetes (MicroK8s)..."
if ! command -v microk8s &> /dev/null; then
    echo "MicroK8s not found. Proceeding with installation."
    snap install microk8s --classic
    usermod -aG microk8s "$TARGET_USER"
    microk8s status --wait-ready
    microk8s enable dns
    microk8s enable storage
    microk8s enable ingress
    microk8s enable metrics-server
    echo "MicroK8s installed and configured successfully."
else
    echo "MicroK8s is already installed. Skipping installation."
fi

echo "--------------------------------------"

# Configure /etc/hosts
echo "Configuring /etc/hosts..."
if ! grep -q "localdevopsplatform.local" /etc/hosts; then
    echo "127.0.0.1 localdevopsplatform.local" >> /etc/hosts
    echo "Successfully added localdevopsplatform.local entry to /etc/hosts."
else
    echo "Entry for localdevopsplatform.local already exists in /etc/hosts. Skipping."
fi

echo "--------------------------------------"
echo "PART 1 completed."
echo "--------------------------------------"
echo "If you are not root, log out and log back in so group changes take effect."
echo "--------------------------------------"