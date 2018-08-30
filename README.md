# Android Universal MAC Changer

This tool lets you change the MAC address of your Android device's wireless interface.  
Superuser privileges are required.

## Features

- Works on every Android version
- Does not require Busybox
- Generate a random address or let user specify one
- Easy to use with lots of documentation

## Quick start

1. Download `changer.sh` to your device's storage.
2. Make sure the script has execution permissions:  
    `/system/bin/chmod +x ./changer.sh`
3. Open a terminal and launch the script as root:  
    `/system/bin/su -c "/system/bin/sh ./changer.sh -h"`