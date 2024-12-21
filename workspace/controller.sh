#!/bin/bash

# Define log file
LOGFILE="/var/log/ansible_install.log"

# Function to log messages
log_message() {
    local MESSAGE="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $MESSAGE" | tee -a "$LOGFILE"
}

# Exit script on any error
set -e

# Trap to catch errors and log them before exiting
trap 'log_message "Error occurred at line $LINENO while executing: $BASH_COMMAND"; exit 1' ERR

log_message "Starting Ansible installation script."

# Update package list
log_message "Updating package list."
apt update -y >> "$LOGFILE" 2>&1

# Install required package
log_message "Installing software-properties-common."
apt install -y software-properties-common >> "$LOGFILE" 2>&1

# Add Ansible repository
log_message "Adding Ansible PPA repository."
apt-add-repository -y ppa:ansible/ansible >> "$LOGFILE" 2>&1

# Update package list again
log_message "Updating package list after adding Ansible repository."
apt update -y >> "$LOGFILE" 2>&1

# Install Ansible
log_message "Installing Ansible."
apt install -y ansible >> "$LOGFILE" 2>&1

# Clone the Git repository
TARGET_DIR="/home/ubuntu"
REPO_URL="https://github.com/thej950/playbooks01.git"
log_message "Cloning repository $REPO_URL into $TARGET_DIR."
cd "$TARGET_DIR" || { log_message "Failed to change directory to $TARGET_DIR"; exit 1; }
git clone "$REPO_URL" >> "$LOGFILE" 2>&1

log_message "Ansible installation and repository cloning completed successfully."


##===================================
##! bin/bash
#apt update -y
#apt install -y software-properties-common
#apt-add-repository ppa:ansible/ansible
#apt update -y
#apt install -y ansible

#cd /home/ubuntu/
#git clone https://github.com/thej950/playbooks01.git

