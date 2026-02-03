#!/bin/bash

# EchoVoice Examples
# This script provides several practical examples of how to integrate echovoice into your workflow.

# 1. System Update Alias (The one requested by you!)
# Add this to your ~/.bashrc or ~/.zshrc for easy updates with voice confirmation.
# alias update='sudo apt update && sudo apt upgrade -y && echovoice "Sistema actualitzat correctament"'
echo "# --- 1. System Update Alias ---"
echo "alias update='sudo apt update && sudo apt upgrade -y && echovoice \"Sistema actualitzat correctament\"'"
echo

# 2. Terminal Greeting
# Add this to your ~/.bashrc to be greeted when opening a new terminal.
# echovoice "Benvingut de nou, $(whoami). Avui és $(date +'%A, %d de %B')."
echo "# --- 2. Terminal Greeting ---"
echo "echovoice \"Benvingut de nou, \$(whoami). Avui és \$(date +'%A, %d de %B').\""
echo

# 3. Notify when a long command finishes
# Perfect for compilations or heavy downloads.
# sleep 5 && echovoice "La tasca ha finalitzat"
echo "# --- 3. Long Task Notification ---"
echo "long_command && echovoice \"S'ha completat la tasca amb èxit\" || echovoice \"Hi ha hagut un error en la tasca\""
echo

# 4. Timer / Countdown
# A simple function to act as a voice timer.
voice_timer() {
    local seconds=$1
    echo "Timer set for $seconds seconds."
    sleep $seconds
    echovoice "El temps s'ha esgotat!"
}
echo "# --- 4. Voice Timer Function ---"
declare -f voice_timer
echo

# 5. Log Monitoring
# Announce when someone logs in (requires root/sudo access to logs).
# sudo tail -f /var/log/auth.log | grep --line-buffered "Accepted password" | while read line; do
#     echovoice "Nou accés detectat al sistema"
# done
echo "# --- 5. Log Monitoring Example ---"
echo "sudo tail -f /var/log/auth.log | grep --line-buffered \"Accepted password\" | while read line; do echovoice \"Nou accés detectat al sistema\"; done"
echo

# 6. Battery Warning (Simple example)
# Note: Requires 'acpi' to be installed.
# battery_level=$(acpi -b | grep -P -o '[0-9]+(?=%)')
# if [ "$battery_level" -le 20 ]; then echovoice "Atenció, bateria baixa: $battery_level per cent"; fi
echo "# --- 6. Battery Warning ---"
echo "battery_level=\$(acpi -b | grep -P -o '[0-9]+(?=%)')"
echo "if [ \"\$battery_level\" -le 20 ]; then echovoice \"Atenció, bateria baixa: \$battery_level per cent\"; fi"
echo
