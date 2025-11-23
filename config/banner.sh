#!/bin/bash

# Claude Switcher ASCII Banner
# Displays branded welcome banner with Andi AI colors

# ANSI Color Codes - Andi AI Blue Theme
# Based on Andi branding: Dodger Blue #3B75FA, Hawkes Blue #D0DFFC, Malibu #7AA4FC
BLUE='\033[1;34m'      # Bright Blue for border
CYAN='\033[1;36m'      # Bright Cyan for main text
DBLUE='\033[0;34m'     # Regular Blue for tagline
RESET='\033[0m'        # Reset color

show_banner() {
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BLUE}│${CYAN}   _____ _                 _        ____          _ _       _        ${BLUE}│${RESET}"
    echo -e "${BLUE}│${CYAN}  / ____| | __ _ _   _  __| | ___  / ___|_      _(_) |_ ___| |__     ${BLUE}│${RESET}"
    echo -e "${BLUE}│${CYAN} | |    | |/ _\` | | | |/ _\` |/ _ \ \___ \ \ /\ / / | __/ __| '_ \    ${BLUE}│${RESET}"
    echo -e "${BLUE}│${CYAN} | |____| | (_| | |_| | (_| |  __/  ___) \ V  V /| | || (__| | | |   ${BLUE}│${RESET}"
    echo -e "${BLUE}│${CYAN}  \_____|_|\__,_|\__,_|\__,_|\___| |____/ \_/\_/ |_|\__\___|_| |_|   ${BLUE}│${RESET}"
    echo -e "${BLUE}│                                                                     │${RESET}"
    echo -e "${BLUE}│${DBLUE}                     Brought to you by Andi AI                       ${BLUE}│${RESET}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}

