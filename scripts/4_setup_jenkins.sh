#!/bin/bash
set -e

export KUBECONFIG=/var/snap/microk8s/current/credentials/client.config

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo privileges. Please run 'sudo ./4_setup_jenkins.sh'"
    exit 1
fi

echo "--------------------------------------"
echo "----------------PART 4----------------"
echo "--------------------------------------"

# Install Java (OpenJDK 21) and set it as the default
echo "Installing Java (OpenJDK 21)..."
if ! command -v java &> /dev/null; then
    apt-get update
    apt-get install -y openjdk-21-jdk
    update-alternatives --set java /usr/lib/jvm/java-21-openjdk-amd64/bin/java 2>/dev/null || \
        echo "Java 21 alternative already set as default."
    update-alternatives --set javac /usr/lib/jvm/java-21-openjdk-amd64/bin/javac 2>/dev/null || \
        echo "Javac 21 alternative already set as default."
    echo "Verifying Java installation..."
    java --version
    echo "Java installed successfully."
else
    echo "Java is already installed."
fi

echo "--------------------------------------"

# Install Jenkins
echo "Installing Jenkins..."
if ! systemctl is-active --quiet jenkins; then
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
        /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
        https://pkg.jenkins.io/debian-stable binary/" | \
        tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    apt-get update
    apt-get install -y jenkins
    usermod -aG docker jenkins
    usermod -aG microk8s jenkins
    if ! grep -q "KUBECONFIG=/var/snap/microk8s/current/credentials/client.config" /etc/default/jenkins 2>/dev/null; then
        echo 'KUBECONFIG=/var/snap/microk8s/current/credentials/client.config' >> /etc/default/jenkins
        echo "Updated /etc/default/jenkins with KUBECONFIG."
    else
        echo "KUBECONFIG is already set in /etc/default/jenkins."    
    fi
    systemctl enable jenkins
    systemctl start jenkins
    sleep 30
    echo "Attempting to allow Jenkins port through the firewall..."
    ufw allow 8080/tcp 2>/dev/null || echo "Firewall not active or port already allowed."
    echo "Jenkins installed and started successfully."
else
    echo "Jenkins is already installed."
fi

echo "--------------------------------------"

echo "Jenkins setup complete."
echo "You can access Jenkins at: localhost:8080"
echo "To retrieve the initial admin password, run:"
echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"


