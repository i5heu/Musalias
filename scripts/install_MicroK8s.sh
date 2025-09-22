#!/bin/bash

# Script Name: install_MicroK8s.sh
# Description: Installs and configures MicroK8s with custom settings.

set -e

# Function to check if a command exists
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed or not in PATH." >&2
        exit 1
    fi
}

# Check for required commands
REQUIRED_COMMANDS=("snap" "sudo")
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    check_command "$cmd"
done

# Update and upgrade the system
echo "Updating and upgrading the system..."
sudo apt update && sudo apt full-upgrade -y

# Check if MicroK8s is installed
if snap list microk8s &> /dev/null; then
    echo "microk8s is already installed. Removing existing installation..."
    sudo snap remove microk8s
fi

# Copy custom MicroK8s config
CONFIG_SOURCE="$HOME/.aliases/microk8s_config.yaml"
CONFIG_DEST="/var/snap/microk8s/common/.microk8s.yaml"

if [ ! -f "$CONFIG_SOURCE" ]; then
    echo "Error: Configuration file $CONFIG_SOURCE does not exist." >&2
    exit 1
fi

echo "Copying MicroK8s configuration..."
sudo mkdir -p /var/snap/microk8s/common/
sudo cp "$CONFIG_SOURCE" "$CONFIG_DEST"

# Install MicroK8s
echo "Installing microk8s..."
sudo snap install microk8s --classic

# Add current user to microk8s group
echo "Adding $USER to microk8s group..."
sudo usermod -aG microk8s "$USER"

# Change ownership of .kube directory
echo "Changing ownership of ~/.kube..."
sudo chown -f -R "$USER":"$USER" ~/.kube

# Wait until MicroK8s is ready
echo "Waiting for microk8s to be ready..."
sudo -u "$USER" microk8s status --wait-ready

# Enable necessary services
echo "Enabling dns and ingress..."
sudo -u "$USER" microk8s enable dns ingress

# Check Kubernetes resources
echo "Fetching all Kubernetes resources..."
sudo -u "$USER" microk8s kubectl get all --all-namespaces

echo "MicroK8s installation and configuration complete."
