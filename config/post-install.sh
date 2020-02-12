#!/usr/bin/env bash

set -x
set -e

# Allow sudo w/o password
echo "hoid ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers

# Add stormlight ssh key
mkdir -p /home/hoid/.ssh
sudo mv /authorized_keys /home/hoid/.ssh/

# Remove password authentication
echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config

# Randomize hoid password because it's in plaintext via the preseed.cfg
echo "hoid:$(openssl rand -base64 30)" | sudo chpasswd
# Then lock the account down
sudo usermod -L hoid

# Disable swap
sudo sed -i '/\/swap/ s/^/#/' /etc/fstab
