#!/bin/bash

DRV_NAME=rtl8814au
DRV_VERSION=5.8.5.1
OPTIONS_FILE=8814au.conf
SCRIPT_NAME=install-driver.sh

if [ $EUID -ne 0 ]
then
	echo "You must run ${SCRIPT_NAME} with superuser priviliges."
	echo "Try: \"sudo ./${SCRIPT_NAME}\""
	exit 1
fi

if [ -d "/usr/lib/dkms" ]
then
	echo "dkms appears to be installed."
else
	echo "dkms does not appear to be installed."
	echo "Try: \"sudo apt install dkms\""
	exit 1
fi

echo "Copying driver source files to: /usr/src/${DRV_NAME}-${DRV_VERSION}"
cp -r $(pwd) /usr/src/${DRV_NAME}-${DRV_VERSION}

echo "Copying ${OPTIONS_FILE} to: /etc/modprobe.d"
cp -r ${OPTIONS_FILE} /etc/modprobe.d

dkms add -m ${DRV_NAME} -v ${DRV_VERSION}
RESULT=$?

if [ "$RESULT" != "0" ]
then
	echo "An error occurred while running: dkms add"
	exit 1
else
	echo "dkms add was successful."
fi

dkms build -m ${DRV_NAME} -v ${DRV_VERSION}
RESULT=$?

if [ "$RESULT" != "0" ]
then
	echo "An error occurred while running: dkms build"
	exit 1
else
	echo "dkms build was successful."
fi

dkms install -m ${DRV_NAME} -v ${DRV_VERSION}
RESULT=$?

if [ "$RESULT" != "0" ]
then
	echo "An error occurred while running: dkms install"
	exit 1
else
	echo "dkms install was successful."
fi
