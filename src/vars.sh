#!/bin/bash

# Save current dir
BASE_CWD=$(pwd)

# The temporary image path
INSTALL_CONFIG_PATH='/hackintosh/config'
INSTALL_BUILD_PATH='/root/tmp'
INSTALL_IMAGE_PATH="${INSTALL_BUILD_PATH}/disk.img"

# The install path (my-boot-image.img, etc)
INSTALL_IMAGE_TARGET='/dev/loop0'
INSTALL_IMAGE_TARGET_PARTITION_ESP='/dev/loop0p1'
INSTALL_IMAGE_TARGET_PARTITION_OC='/dev/loop0p2'

# The mountpoints we'll be using
INSTALL_MOUNT_ROOT='/mnt'
INSTALL_MOUNT_ESP="${INSTALL_MOUNT_ROOT}/boot"
INSTALL_MOUNT_OC="${INSTALL_MOUNT_ROOT}/ocboot"

# The link to OpenCore's version we'll be using
INSTALL_OPENCORE_BUILD='https://github.com/acidanthera/OpenCorePkg/releases/download/0.6.1/OpenCore-0.6.1-RELEASE.zip'
INSTALL_OPENCORE_FILE='OpenCore.zip'
INSTALL_OPENCORE_DIR='OpenCoreBase'