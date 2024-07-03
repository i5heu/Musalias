#!/bin/bash

# Update packages and upgrade the system
sudo apt update
sudo apt full-upgrade -y

# Check if microk8s is already installed and install it if not
if snap list microk8s 1>/dev/null 2>&1; then
    echo "microk8s is already installed."
else
    echo "microk8s is not installed, attempting to install..."
    sudo snap install microk8s --classic
fi

# Add the current user to the microk8s group and change ownership of .kube directory
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER:$USER ~/.kube

# Ensure microk8s is ready and enable necessary services
sudo -u $USER microk8s status --wait-ready
sudo -u $USER microk8s enable dns ingress

# Execute kubectl command to check resources
sudo -u $USER microk8s kubectl get all --all-namespaces
