#!/bin/bash
# Usage: ./install.sh /path-to-file.img

[[ -z "$1" ]] && { echo 'Usage: /hackintosh/finish.sh out/disk.img' ; exit 1; }

# We *MUST* be running as root/sudo
if [ $EUID != 0 ]; then
  sudo "$0" "$@"
  exit $?
fi

# Output file
INSTALL_IMAGE_OUTPUT_PATH="$1"

# Loads base vars
source '/hackintosh/vars.sh'

echo ""
echo "-> Unmounting devices..."

echo "--> '${INSTALL_MOUNT_ESP}'..."
umount "${INSTALL_MOUNT_ESP}"

echo "--> '${INSTALL_MOUNT_OC}'..."
umount "${INSTALL_MOUNT_OC}"

echo "--> '${INSTALL_IMAGE_TARGET}'..."
losetup -d "${INSTALL_IMAGE_TARGET}"

echo ""
echo "-> Moving output image file..."

cd "${BASE_CWD}"
rm -f ${INSTALL_IMAGE_OUTPUT_PATH}
mv "${INSTALL_IMAGE_PATH}" ${INSTALL_IMAGE_OUTPUT_PATH}

echo ""
echo "-> Done. Now burn the output file and have fun! :)"