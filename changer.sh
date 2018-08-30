#!/system/bin/sh

#===--------------- Android Universal MAC Changer ----------------===#
#                                                                    #
#                    works on ANY android device,                    #
#                       no matter the version.                       #
#===---------------- "it only needs root access" -----------------===#

#====================================================================#
#                                                                    #
#       Copyright (c) 2018 hypothermic <admin@hypothermic.nl>        #
#                                                                    #
#    Permission is hereby granted, free of charge, to any person     #
#   obtaining a copy of this software and associated documentation   #
#      files (the "Software"), to deal in the Software without       #
#    restriction, including without limitation the rights to use,    #
#  copy, modify, merge, publish, distribute, sublicense, and/or sell #
# copies of the Software, and to permit persons to whom the Software #
#     is furnished to do so, subject to the following conditions:    #
#                                                                    #
#   The above copyright notice and this permission notice shall be   #
#   included in all copies or substantial portions of the Software.  #
#                                                                    #
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,  #
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF #
#        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND       #
#     NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    #
#    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,    #
#        WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,        #
#      ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE       #
#           OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.            #
#====================================================================#

# --- Variables

NET_INTERFACE=wlan0
NEW_ADDRESS=undefined
USE_BUSYBOX=0

# --- Functions

usage()
{
    echo ""
    echo "Usage: changer.sh [-r | -a 00:00:00:00:00] [-hb]"
    echo ""
    echo "  -a <addr>  specify a specific address"
    echo "  -r         generate a random mac address to use"
    echo "  -h         show this help message"
    echo "  -b         enable busybox mode (default: /system/xbin)"
    echo ""
    echo " NOTE: use -r OR -a, not both."
    echo ""
    exit 0
}

main()
{
    echo ""
    echo "=== Android Universal MAC Changer ==="
    echo ">> Current hwaddress: $(cat /sys/class/net/"$NET_INTERFACE"/address)"
    if ! [ $(id -u) = 0 ]; then
        echo "Elevating to root shell..."
        if [ "$USE_BUSYBOX" = 1 ]; then
            /system/xbin/su -c "/system/xbin/sh"
        else
            /system/bin/su -c "/system/bin/sh"
        fi
    fi

    if [ -x "$(command -v svc)" ]; then
        echo "- Disabling Wi-Fi using svc..."
        svc wifi disable
    else
        echo "- Taking down $NET_INTERFACE using ifconfig..."
        ifconfig "$NET_INTERFACE" down
    fi

    echo "- Changing MAC address to $NEW_ADDRESS"
    ifconfig $NET_INTERFACE hw ether $NEW_ADDRESS

    if [ -x "$(command -v svc)" ]; then
        echo "- Enabling Wi-Fi using svc..."
        svc wifi enable
    else
        echo "- Restoring $NET_INTERFACE using ifconfig..."
        ifconfig "$NET_INTERFACE" up
    fi

    if [ $(cat /sys/class/net/"$NET_INTERFACE"/address) = "$NEW_ADDRESS" ]; then
        echo ""
        echo ">> Congratulations!"
        echo "Your new MAC address for $NET_INTERFACE is $NEW_ADDRESS"
        echo "This change will persist until the device is rebooted."
        echo ""
    else
        echo ""
        echo ">> Unfortunately the changes didn't work."
        echo "Please submit a bug report to our Git repository:"
        echo "https://www.github.com/hypothermic/android-mac-changer"
        echo ""
    fi
}

# --- Logic

while [ "$1" != "" ]; do
    case $1 in
        -a|--address)
            if [ -n "$2" ]; then
                NEW_ADDRESS="$2"
                echo "INFO: the MAC address you entered will not be verified, I hope you entered a valid one..."
                shift 2
                continue
            else
                echo "ERROR: '$1' requires a non-empty option argument."
                exit 1
            fi
            ;;
        -r|--random)
            # not the cleanest code ever but it'll do.
            while [ "$NEW_ADDRESS" = "undefined" ]; do
                NEW_ADDRESS=$(printf '%02X:%02X:%02X:%02X:%02X:%02X\n' $(($(date +%N) % 60)) $(($(date +%N) % 60)) $(($(date +%N) % 60)) $(($(date +%N) % 60)) $(($(date +%N) % 60)) $(($(date +%N) % 60)))
            done
            ;;
        -i|--interface)
            if [ -n "$2" ]; then
                NET_INTERFACE="$2"
                shift 2
                continue
            else
                echo "ERROR: '$1' requires a non-empty option argument."
                exit 2
            fi
            ;;
        -b|--busybox)
            USE_BUSYBOX=1
            ;;
        -h|--help|--usage)
            usage
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "ERROR: unknown parameter \"$1\""
            usage
            exit 3
            ;;
    esac
    shift
done

if [ "$NEW_ADDRESS" = "undefined" ]; then
    echo "ERROR: no MAC address specified, use either -r or -a"
    exit 4
fi

if ! [ -e "/system/build.prop" ]; then
    echo "ERROR: this script can only be run on Android devices."
    exit 5
fi

main