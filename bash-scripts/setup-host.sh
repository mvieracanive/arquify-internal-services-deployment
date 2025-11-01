#!/bin/bash
# ===================================================
# Arquify Internal Services - Main Control Script
# Provides an interactive menu to run common tasks
# Author: Maia Viera
# Date: 2025-11-01
# ===================================================

set -euo pipefail

# --- Menu ---
show_menu() {
    clear
    echo "==============================================="
    echo " 🚀 Arquify Internal Services Control Menu"
    echo "==============================================="
    echo " 1) Configure Logrotate for Arquify logs"
    echo " 2) Download internal services repository"
    echo " 3) Configure Logrotate for Arquify logs"
    echo " 4) Install Docker"
    echo " 5) Install SFTP"
    echo " 6) Install IpTable"
    echo " 7) Update and Patch System"
    echo " 8) Exit"
    echo "-----------------------------------------------"
    read -rp "Select an option [1-8]: " choice
}

# --- Actions ---
configure_logrotate() {
  bash config-logrotate.sh;
}

install_docker() {
  bash install-docker.sh;
}

install_sftp() {
  echo "installing sftp...";
}

install_iptable() {
  echo "installing iptable...";
}

patch_system() {
    echo "patching system...";
}

chmod u+x *.sh

while true; do
    show_menu
    case "$choice" in
        1)
            configure_logrotate
            ;;
        2)
            configure_logrotate
            ;;
        3)
            configure_logrotate
            ;;
        4)
            install_docker
            ;;
        5)
            install_sftp
            ;;
        6)
            install_iptable
            ;;
        7)
            patch_system
            ;;
        8)
            echo "👋 Exiting..."
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please try again."
            ;;
    esac

    echo ""
    read -rp "Press Enter to continue..." pause
done
