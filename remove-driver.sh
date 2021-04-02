#!/bin/bash

SCRIPT_NAME="remove-driver.sh"
SCRIPT_VERSION="20210401"

DRV_NAME="rtl8814au"
DRV_VERSION="5.8.5.1"
OPTIONS_FILE="8814au.conf"

if [[ $EUID -ne 0 ]]
then
	echo "You must run this script with superuser (root) privileges."
	echo "Try \"sudo ./${SCRIPT_NAME}\""
	exit 1
fi

dkms remove -m ${DRV_NAME} -v ${DRV_VERSION} --all
RESULT=$?

if [[ "$RESULT" != "0" ]]
then
	echo "An error occurred while running: dkms remove : ${RESULT}"
	echo "Please report errors."
	exit $RESULT
else
	rm -f /etc/modprobe.d/${OPTIONS_FILE}
	rm -rf /usr/src/${DRV_NAME}-${DRV_VERSION}
	echo "The driver was removed successfully."
fi

read -p "Are you ready to reboot now? [y/n] " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    reboot
fi

exit 0
