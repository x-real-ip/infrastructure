#!/bin/bash
#
# Script to update, maintain and/or reboot all Shelly devices in local network with this single script.
# Writtin by Coen Stam.
# github@theautomation.nl
#

domain="lan"
ip_subnet="10.0.40"
ip_start="99"
ip_end="140"

#--------------------------------

# Install jq if not present.
if ! jq --version >/dev/null; then
    read -p "jq is required for this script, do you want to install jq? (yes/no) " yn
    case $yn in
    yes)
        sudo apt-get install jq -y && clear &&
            echo -e "jq successfully installed\n"
        ;;
    no)
        echo exiting...
        exit
        ;;
    *)
        echo invalid response
        exit 1
        ;;
    esac
fi

nameFqdn() { name=$(curl -s -m 1 "http://${ip_subnet}.${i}/settings" | jq -cr '.name' 2>/dev/null) &&
    fqdn=$(curl -s -m 1 "http://${ip_subnet}.${i}/settings" | jq -cr '.device.hostname' 2>/dev/null); }

tableRow() { printf "| %-35s| %-35s| %-35s\n" "$1" "$2" "$3"; }

tableLine() { printf '%s\n' "|--------------------------------------------------------------------------------------------------------------"; }

# Choose actions
PS3='Choose an action for all Shelly devices: '
actions=("List devices" "Reboot" "Check for new firmware version" "Update firmware version" "Enable and edit CoIoT" "Set SNTP IP Address" "Quit")
select action in "${actions[@]}"; do
    case $action in
    "List devices")
        echo -e "\nSearch IP range for Shelly devices, this can take several minutes...\n"
        tableRow "Name" "Ip Address" "FQDN"
        tableLine
        for i in $(seq ${ip_start} ${ip_end}); do
            nameFqdn
            if [ -n "${name}" ]; then tableRow "${name}" "192.168.40.${i}" "http://${fqdn}.${domain}"; fi
        done
        echo "Done..."
        ;;
    "Reboot")
        echo -e "\nAll Shelly devices will now rebooting, this can take several minutes...\n"
        tableRow "Name" "Status" "FQDN"
        tableLine
        for i in $(seq ${ip_start} ${ip_end}); do
            nameFqdn
            status=$(curl -s -m 1 "http://${ip_subnet}.${i}/reboot" | jq -cr '.ok' 2>/dev/null)
            if [ "${status}" = "true" ]; then tableRow "${name}" "Restarted" "http://${fqdn}.${domain}"; elif [ "${status}" = "false" ]; then tableRow "${name}" "Restart failed" "http://${fqdn}.${domain}"; fi
        done
        echo "Done..."
        ;;
    "Check for new firmware version")
        echo -e "\nManually check new firmware updates for all Shelly devices, this can take several minutes...\n"
        tableRow "Name" "Status" "FQDN"
        tableLine
        for i in $(seq ${ip_start} ${ip_end}); do
            nameFqdn
            status=$(curl -s -m 1 "http://${ip_subnet}.${i}/ota/check" | jq -cr '.status' 2>/dev/null)
            if [ "${status}" = "ok" ]; then tableRow "${name}" "Checked firmware" "http://${fqdn}.${domain}"; fi
        done
        echo -e "\nCheck if Shelly devices can be updated, this can take several minutes...\n"
        for i in $(seq ${ip_start} ${ip_end}); do
            status=$(curl -s -m 1 "http://${ip_subnet}.${i}/ota/has_update" | jq -cr '.has_update' 2>/dev/null)
            if [ "${status}" = "true" ]; then tableRow "${name}" "Firmware available" "http://${fqdn}.${domain}"; fi
        done
        ;;
    "Update firmware version")
        echo -e "\nUpdate all Shelly devices to new firmware version if available, this can take several minutes...\n"
        tableRow "Name" "Status" "FQDN"
        tableLine
        for i in $(seq ${ip_start} ${ip_end}); do
            nameFqdn
            status=$(curl -s -m 1 "http://${ip_subnet}.${i}/ota?update=true" | jq -cr '.status, .has_update' 2>/dev/null)
            if [ "${status}" = "updating true" ]; then tableRow "${name}" "Updating" "http://${fqdn}.${domain}"; fi
        done
        echo "Done..."
        ;;
    "Enable and edit CoIoT")
        read -p "Enter CoIoT peer IP address: " coiot_peer
        echo -e "\nUpdate CoIoT on all Shelly devices, this can take several minutes...\n"
        tableRow "Name" "Status" "FQDN"
        tableLine
        for i in $(seq ${ip_start} ${ip_end}); do
            nameFqdn
            status=$(curl -s -m 1 "http://${ip_subnet}.${i}/settings?coiot_enable=true&coiot_peer=${coiot_peer}" | jq -cr '.coiot.enabled' 2>/dev/null)
            if [ "${status}" = "true" ]; then tableRow "${name}" "CoIoT peer set to ${coiot_peer}" "http://${fqdn}.${domain}"; fi
        done
        echo "Done..."
        echo "2) Reboot required when CoIoT peer is changed!, choose option 2"
        ;;
    "Set SNTP IP Address")
        read -p "Enter SNTP IP address: " input
        echo -e "\nUpdate SNTP on all Shelly devices, this can take several minutes...\n"
        tableRow "Name" "Status" "FQDN"
        tableLine
        for i in $(seq ${ip_start} ${ip_end}); do
            nameFqdn
            status=$(curl -s -m 1 "http://${ip_subnet}.${i}/settings?sntp_enable=true&sntp_server=${input}" | jq -cr '.sntp.enabled' 2>/dev/null)
            if [ "${status}" = "true" ]; then tableRow "${name}" "SNTP IP address is set to ${input}" "http://${fqdn}.${domain}"; fi
        done
        echo "Done..."
        echo "2) Reboot required when SNTP is changed!, choose option 2"
        ;;
    "Quit")
        echo "exiting..."
        exit
        ;;
    *) echo "invalid option $REPLY" ;;
    esac
done
