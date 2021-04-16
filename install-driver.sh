#!/bin/bash

SCRIPT_NAME="install-driver.sh"
SCRIPT_VERSION="20210416"

DRV_NAME="rtl8814au"
DRV_VERSION="5.8.5.1"
OPTIONS_FILE="8814au.conf"

DRV_DIR="$(pwd)"
KRNL_VERSION="$(uname -r)"

clear
echo "${SCRIPT_NAME} version ${SCRIPT_VERSION}"

# check to ensure sudo was used
if [[ $EUID -ne 0 ]]
then
	echo "You must run this script with superuser (root) privileges."
	echo "Try: \"sudo ./${SCRIPT_NAME}\""
	exit 1
fi

# check for previous installation
if [[ -d "/usr/src/${DRV_NAME}-${DRV_VERSION}" ]]
then
	echo "It appears that this driver may already be installed."
	echo "You will need to run the following before installing."
	echo "$ sudo ./remove-driver.sh"
	exit 1
fi

echo "Start installation."
# the add command requires source in /usr/src/${DRV_NAME}-${DRV_VERSION}
echo "Copying source files to: /usr/src/${DRV_NAME}-${DRV_VERSION}"
cp -rf "${DRV_DIR}" /usr/src/${DRV_NAME}-${DRV_VERSION}
echo "Copying ${OPTIONS_FILE} to: /etc/modprobe.d"
cp -f ${OPTIONS_FILE} /etc/modprobe.d

dkms add -m ${DRV_NAME} -v ${DRV_VERSION}
RESULT=$?

if [[ "$RESULT" != "0" ]]
then
	echo "An error occurred. dkms add error = ${RESULT}"
	echo "Please report this error."
	exit $RESULT
fi

dkms build -m ${DRV_NAME} -v ${DRV_VERSION}
RESULT=$?

if [[ "$RESULT" != "0" ]]
then
	echo "An error occurred. dkms build error = ${RESULT}"
	echo "Please report this error."
	exit $RESULT
fi

dkms install -m ${DRV_NAME} -v ${DRV_VERSION}
RESULT=$?

if [[ "$RESULT" != "0" ]]
then
	echo "An error occurred. dkms install error = ${RESULT}"
	echo "Please report this error."
	exit $RESULT
fi

echo "The driver was installed successfully."

read -p "Do you want edit the driver options file now? [y/n] " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    nano /etc/modprobe.d/${OPTIONS_FILE}
fi

read -p "Are you ready to reboot now? [y/n] " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    reboot
fi

exit 0
