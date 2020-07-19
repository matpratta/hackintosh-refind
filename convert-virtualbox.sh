#!/bin/bash
# Usage: ./convert-virtualbox.sh out/disk.img

# Check if path exists
[[ -z "$1" ]] && { echo 'Usage: ./convert-virtualbox.sh out/disk.img' ; exit 1; }

VBoxManage convertdd "$1" "$1.vdi" --format VDI