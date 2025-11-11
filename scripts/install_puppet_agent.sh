#!/bin/bash
set -e

# This script installs puppet-agent (example for Ubuntu 20.04)
# Update repos
sudo apt-get update -y

# Install prerequisites
sudo apt-get install -y wget ca-certificates

# Add Puppet APT repo (Puppet 7 example)
wget https://apt.puppet.com/puppet7-release-focal.deb -O /tmp/puppet7-release.deb
sudo dpkg -i /tmp/puppet7-release.deb
sudo apt-get update -y

# Install puppet-agent
sudo apt-get install -y puppet-agent

# Enable and start puppet service if present
if systemctl list-unit-files | grep -q puppet; then
  sudo systemctl enable puppet
  sudo systemctl start puppet
fi

# basic check
/opt/puppetlabs/bin/puppet --version || echo "Puppet agent may not have been installed successfully"
