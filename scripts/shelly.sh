#!/bin/bash
#
# Script to maintain all Shelly devices in local network.
# Writtin by Coen Stam.
# github@theautomation.nl
#

domain="lan"
shelly_devices=(
    "
    shelly1-40f520053a34
    shellydimmer2-E8DB84D4411C
    shelly1-768885
    "
)

    # shellyplug-s-DD9EA4
    # shellydimmer-F39FBB
    # shellydimmer-F3A9E8
    # shellyplug-s-801BEA
    # shellyplug-s-DCB062
    # shellyplug-s-DBF101
    # shellyplug-s-0212C1
    # shellydimmer-F36684
    # shellydimmer-F36674
    # shellydimmer-DB4094
    # shellydimmer-DB3DDA
    # shellydimmer-DB3BAF
    # shellydimmer-F3A2DA
    # shellydimmer-D4826F
    # shellyplug-s-DD4D06
    # shellyplug-s-DE0CDF
    # shellydimmer2-E8DB84D794FD


PS3='Choose an action for all Shelly devices: '
actions=("Show devices" "Reboot" "Check for updates" "Update" "Quit")
select action in "${actions[@]}"; do
    case $action in
        "Show devices")
            echo "List of all Shelly devices: "
            for d in ${shelly_devices}; do
                echo "$d"
            done
            ;;
        "Reboot")
            echo "All Shelly devices will now rebooting..."
            for d in ${shelly_devices}; do
                curl http://${d}.${domain}/reboot
                echo ""
            done
            ;;
        "Check for updates")
            echo "Check updates for all Shelly devices..."
            for d in ${shelly_devices}; do
                curl http://${d}.${domain}/ota/check
                echo ""
            done
            ;;
        "Update")
            echo "Update all Shelly devices..."
            for d in ${shelly_devices}; do
                curl http://${d}.${domain}/ota
                echo ""
            done
            ;;
	"Quit")
        echo "Script exited"
        exit
        ;;
        *) echo "invalid option $REPLY";;
    esac
done
