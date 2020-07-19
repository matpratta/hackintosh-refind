#!/bin/bash
# Usage: ./install.sh

# We *MUST* be running as root/sudo
if [ $EUID != 0 ]; then
  sudo "$0" "$@"
  exit $?
fi

# Loads base vars
source '/hackintosh/vars.sh'

# Prepare mount points
umount "${INSTALL_MOUNT_ESP}"
umount "${INSTALL_MOUNT_OC}"
rm -rf "${INSTALL_BUILD_PATH}"
rm -rf "${INSTALL_MOUNT_ESP}"
rm -rf "${INSTALL_MOUNT_OC}"
mkdir "${INSTALL_BUILD_PATH}"
mkdir "${INSTALL_MOUNT_ESP}"
mkdir "${INSTALL_MOUNT_OC}"

# Generate and mount empty disk image of ~512MiB

echo ""
echo "-> Generating empty image file at '${INSTALL_IMAGE_PATH}'..."

losetup -d "${INSTALL_IMAGE_TARGET}"
rm -f "${INSTALL_IMAGE_PATH}"
touch "${INSTALL_IMAGE_PATH}"
dd if=/dev/zero of="${INSTALL_IMAGE_PATH}" count=1024k status=progress

echo ""
echo "-> Mounting image file '${INSTALL_IMAGE_PATH}'..."
losetup "${INSTALL_IMAGE_TARGET}" "${INSTALL_IMAGE_PATH}"

# Initialize new disk image and prepare our boot partition (thanks https://superuser.com/a/984637)

echo ""
echo "-> Initializing disk at '${INSTALL_IMAGE_TARGET}'..."

# Completely empties any partition data on the disk (which should be empty)
echo ""
echo "--> Zapping any possibly existing data..."
sgdisk --zap-all "${INSTALL_IMAGE_TARGET}"
partprobe "${INSTALL_IMAGE_TARGET}"

# Redundancy but whatever
echo ""
echo "--> Initializing GPT..."
sgdisk --clear "${INSTALL_IMAGE_TARGET}"
partprobe "${INSTALL_IMAGE_TARGET}"

# Redundancy but whatever
echo ""
echo "--> Creating rEFInd partition..."
sgdisk --new=1:+0:+111M "${INSTALL_IMAGE_TARGET}"
sgdisk --change-name=1:"BOOT_REFIND" "${INSTALL_IMAGE_TARGET}"
sgdisk --typecode=1:ef00 "${INSTALL_IMAGE_TARGET}"
partprobe "${INSTALL_IMAGE_TARGET}"

# Redundancy but whatever
echo ""
echo "--> Creating OpenCore partition..."
sgdisk --new=2:+0:+0 "${INSTALL_IMAGE_TARGET}"
sgdisk --change-name=2:"BOOT_OPENCORE" "${INSTALL_IMAGE_TARGET}"
sgdisk --typecode=2:ef00 "${INSTALL_IMAGE_TARGET}"
partprobe "${INSTALL_IMAGE_TARGET}"

#sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk "${INSTALL_IMAGE_TARGET}"
#  o     # reset in-memory GPT
#  y     # "yes"
#  n     # new partition (EFI System Partition)
#  1     # partition number 1
#        # default - start at beginning of disk 
#  +100M # span ~100MiB since this will only be for rEFInd
#  ef00  # make the partition type EFI
#  n     # new partition (OpenCore)
#  2     # partition number 2
#        # default - start at end of last section
#        # default - span to the end of disk (~412MiB) for OpenCore
#  ef00  # make the partition type EFI
#  c     # change partition name
#  1     # partition 1
#  RBOOT # write the main bootloader name
#  c     # change partition name
#  2     # partition 2
#  OCORE # write the open core name
#  w     # write the partition table
#  y     # "yes"
#EOF

#sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk "${INSTALL_IMAGE_TARGET}"
#  o     # clear the in memory partition table
#  n     # new partition (EFI System Partition)
#  p     # primary partition
#  1     # partition number 1
#        # default - start at beginning of disk 
#  +100M # span ~100MiB since this will only be for rEFInd
#  t     # select partition type
#  ef    # make the partition type EFI
#  a     # make a partition bootable
#  n     # new partition (OpenCore)
#  p     # primary partition
#  2     # partition number 2
#        # default - start at end of last section
#        # default - span to the end of disk (~412MiB) for OpenCore
#  t     # select partition type
#  2     # for partition 2
#  ef    # make the partition type EFI
#  p     # print the in-memory partition table
#  w     # write the partition table
#  q     # and we're done
#EOF

# Converts disk to GPT

#echo ""
#echo "-> Converting disk at '${INSTALL_IMAGE_TARGET}' to GPT..."

#sgdisk -g "${INSTALL_IMAGE_TARGET}"

# Updates the kernel partition table

echo ""
echo "-> Updating kernel partition table..."

partprobe "${INSTALL_IMAGE_TARGET}"

# Initializes EFI partition

echo ""
echo "-> Formatting EFI partition at '${INSTALL_IMAGE_TARGET_PARTITION_ESP}'..."

mkfs.vfat -F 32 "${INSTALL_IMAGE_TARGET_PARTITION_ESP}" -n 'REFIND'

echo ""
echo "-> Mounting EFI partition '${INSTALL_IMAGE_TARGET_PARTITION_ESP}' at '${INSTALL_MOUNT_ESP}'..."

mount "${INSTALL_IMAGE_TARGET_PARTITION_ESP}" "${INSTALL_MOUNT_ESP}"

echo ""
echo "-> Preparing EFI mount at '${INSTALL_MOUNT_ROOT}'..."

rm -rf "${INSTALL_MOUNT_ESP}/*"

# Runs rEFInd installer
echo ""
echo "-> Installing rEFInd to '${INSTALL_MOUNT_ESP}'..."

refind-install --root "${INSTALL_MOUNT_ROOT}"

# Cleanup the build directory
echo ""
echo "-> Cleaning-up build directory..."
cd "${INSTALL_BUILD_PATH}"
rm -rf "${INSTALL_BUILD_PATH}/build"
mkdir "${INSTALL_BUILD_PATH}/build"
cd "${INSTALL_BUILD_PATH}/build"

# Download and unzip OpenCore

echo ""
echo "-> Downloading OpenCore from '${INSTALL_OPENCORE_BUILD}'..."
wget -O "${INSTALL_OPENCORE_FILE}" "${INSTALL_OPENCORE_BUILD}"

echo ""
echo "-> Extracting OpenCore..."
unzip "${INSTALL_OPENCORE_FILE}" -d "${INSTALL_OPENCORE_DIR}"

# Initializes OpenCore partition

echo ""
echo "-> Formatting OpenCore partition at '${INSTALL_IMAGE_TARGET_PARTITION_OC}'..."

mkfs.vfat -F 32 "${INSTALL_IMAGE_TARGET_PARTITION_OC}" -n 'OPENCORE'

echo ""
echo "-> Mounting OpenCore partition '${INSTALL_IMAGE_TARGET_PARTITION_OC}' at '${INSTALL_MOUNT_OC}'..."

mount "${INSTALL_IMAGE_TARGET_PARTITION_OC}" "${INSTALL_MOUNT_OC}"

echo ""
echo "-> Preparing OpenCore mount at '${INSTALL_MOUNT_ROOT}'..."

rm -rf "${INSTALL_MOUNT_OC}/*"

# Copies OpenCore release files to its partition
echo ""
echo "-> Installing OpenCore to '${INSTALL_MOUNT_OC}'..."

cp -r "${INSTALL_BUILD_PATH}/build/${INSTALL_OPENCORE_DIR}"/EFI/ "${INSTALL_MOUNT_OC}"

# Any rEFInd settings customizations should go to the refind-settings.conf file, as they are appended to the standard settings file
echo ""
echo "-> Configuring rEFInd..."

cp "${INSTALL_CONFIG_PATH}/refind/refind-settings.conf" "${INSTALL_MOUNT_ESP}/EFI/BOOT/refind-settings.conf"
echo 'include chainload-oc.conf' >> "${INSTALL_MOUNT_ESP}/EFI/BOOT/refind.conf"

# Extracts OpenCore partition's UUID and configure it on rEFInd
# This step will:
# - Register a custom OpenCore entry on rEFInd
# - Make it ignore the entire OpenCore EFI partition when scanning for OSes and EFIs
echo ""
echo "-> Configuring OpenCore as chainload EFI..."

CONFIG_UUID_OPENCORE=$(sudo sgdisk -i 2 /dev/loop0 | grep 'Partition unique GUID' | tr ": " "\n" | tail -n 1)
echo "--> OpenCore partition UUID: ${CONFIG_UUID_OPENCORE}"

cp "${INSTALL_CONFIG_PATH}/refind/chainload-oc.conf" "${INSTALL_MOUNT_ESP}/EFI/BOOT/chainload-oc.conf"
sed -i "s/#{CONFIG_UUID_OPENCORE}/${CONFIG_UUID_OPENCORE}/g" "${INSTALL_MOUNT_ESP}/EFI/BOOT/chainload-oc.conf"

# Generates the startup.nsh to tell where to start the firmware
echo ""
echo "-> Configuring EFI 'startup.nsh'..."

echo '\EFI\BOOT\bootx64.efi' > "${INSTALL_MOUNT_ESP}/startup.nsh"

# Done.
echo ""
echo "-> Base system creation done."

echo "--> rEFInd Install Directory: '${INSTALL_MOUNT_ESP}/EFI/BOOT/'"
echo "--> OpenCore Install Directory: '${INSTALL_MOUNT_OC}/EFI/OC/'..."

echo ""
echo "Please, finish setting-up your OpenCore and rEFInd as you please, then finish the installation with '/hackintosh/finish.sh out/disk.img'"
echo ""

cd "${BASE_CWD}"