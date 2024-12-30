#!/bin/bash

# Colors and formatting using tput
bold=$(tput bold)
normal=$(tput sgr0)
yellow=$(tput setaf 3)
green=$(tput setaf 2)
blue=$(tput setaf 4)
cyan=$(tput setaf 6)
red=$(tput setaf 1)
magenta=$(tput setaf 5)

# Functions for diagnostics
cpu_usage() {
    echo -e "${bold}${green}== CPU USAGE ==${normal}"
    uptime
    echo ""
}

memory_usage() {
    echo -e "${bold}${green}== MEMORY USAGE ==${normal}"
    free -h
    echo ""
}

disk_usage() {
    echo -e "${bold}${green}== DISK USAGE ==${normal}"
    df -h
    echo ""
}

network_usage() {
    echo -e "${bold}${green}== NETWORK USAGE ==${normal}"
    ip -s link
    echo ""
}

top_processes() {
    echo -e "${bold}${green}== TOP 5 PROCESSES BY CPU & MEMORY USAGE ==${normal}"
    ps aux --sort=-%cpu,-%mem | head -n 6
    echo ""
}

security_diagnostics() {
    echo -e "${bold}${green}== SECURITY DIAGNOSTICS ==${normal}"
    echo -e "${blue}Open Ports:${normal}"
    ss -tuln
    echo -e "\n${blue}Failed Login Attempts:${normal}"
    grep "Failed password" /var/log/auth.log | tail -n 5
    echo ""
}

storage_insights() {
    echo -e "${bold}${green}== STORAGE INSIGHTS ==${normal}"
    echo -e "${blue}Largest Files:${normal}"
    du -ah / | sort -rh | head -n 10
    echo -e "\n${blue}Inode Usage:${normal}"
    df -i
    echo ""
}

load_average() {
    echo -e "${bold}${green}== LOAD AVERAGE & UPTIME ==${normal}"
    uptime
    echo ""
}

bandwidth_usage() {
    echo -e "${bold}${green}== BANDWIDTH USAGE ==${normal}"
    if command -v vnstat &> /dev/null; then
        vnstat
    else
        echo -e "${red}vnstat is not installed. Please install it to monitor bandwidth.${normal}"
    fi
    echo ""
}

package_updates() {
    echo -e "${bold}${green}== PACKAGE UPDATES ==${normal}"
    if command -v apt &> /dev/null; then
        apt list --upgradable
    else
        echo -e "${red}Package manager not supported by this script.${normal}"
    fi
    echo ""
}

# Display menu
while true; do
    clear
    echo -e "${bold}${yellow}==== VPS DIAGNOSTIC TOOL ====${normal}"
    echo -e "Choose an option from the menu below:"
    echo -e "${green}1) CPU Usage${normal}"
    echo -e "${green}2) Memory Usage${normal}"
    echo -e "${green}3) Disk Usage${normal}"
    echo -e "${green}4) Network Usage${normal}"
    echo -e "${green}5) Top Processes${normal}"
    echo -e "${green}6) Security Diagnostics${normal}"
    echo -e "${green}7) Storage Insights${normal}"
    echo -e "${green}8) Load Average & Uptime${normal}"
    echo -e "${green}9) Bandwidth Usage${normal}"
    echo -e "${green}10) Package Updates${normal}"
    echo -e "${green}11) Exit${normal}"
    echo ""
    read -p "Enter your choice: " choice

    case $choice in
        1) cpu_usage ;;
        2) memory_usage ;;
        3) disk_usage ;;
        4) network_usage ;;
        5) top_processes ;;
        6) security_diagnostics ;;
        7) storage_insights ;;
        8) load_average ;;
        9) bandwidth_usage ;;
        10) package_updates ;;
        11) echo -e "${bold}Exiting...${normal}" ; exit 0 ;;
        *) echo -e "${red}Invalid option. Please try again.${normal}" ;;
    esac

    read -p "Press Enter to return to the menu..."
done
