# Welcome to Hackintosh-rEFInd!

This project is meant to be a blueprint for preparing a bare-bones [rEFInd](https://www.rodsbooks.com/refind/) install with [OpenCore](https://github.com/acidanthera/OpenCorePkg) installed as a chainloaded EFI.

## Usage

Clone this repository and `cd` into it, then run `vagrant up && vagrant ssh` to initialize the Vagrant image build environment.

With the environment up and running, execute `/hackintosh/install.sh` to start building the USB image file. The final disk image will contain **two** EFI System Partitions laid-out on a 512MiB GPT disk. These partitions are both formatted as `vFAT/FAT32`, one with 112MiB (reserved to rEFInd) and one with 400MiB (reserved for OpenCore).

The rEFInd installation comes configured so that you have a proper OpenCore entry on rEFInd's menu, while still automatically detecting other OSes and EFIs.

At this point you can finish editing the files on both rEFInd and OpenCore, and when done simply run `/hackintosh/finish.sh out/disk.img` to generate the final IMG file. This file is automatically available on your host machine under the `out` directory.

After that's done, you can burn this image into a USB flash drive using something like [balenaEtcher](https://www.balena.io/etcher/). Just keep in mind you still need to setup OpenCore, since all this does is installing it.

## Things that still aren't 100% done

Most of this stuff is a proof-of-concept, so take all of this with a big spoon of salt, please.

While generating the USB bootloader is completely possible using this tool, this won't generate you any disk entries or anything similar just yet (in an actual SSD, for example). This is still planned as a stand-alone tool for using on bare metal installs, but just not ready yet. Please keep this in mind.