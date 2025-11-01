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
    echo " 1) Download internal services repository"
    echo " 2) Set execution permission to deployment scripts"
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
download_repository() {
  echo "downloading repo...";
}

set_x_permission_to_scripts() {
  echo "setting permissions...";  
}

configure_logrotate() {
  echo "configure logrotate...";
}

install_docker() {
  echo "installing docker...";
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



while true; do
    show_menu
    case "$choice" in
        1)
            download_repository
            ;;
        2)
            set_x_permission_to_scripts
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
