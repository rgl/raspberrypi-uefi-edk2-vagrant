#!/bin/bash
source rpi4-uefi-environment.sh
set -euxo pipefail

# build.
NUM_CPUS=$((`getconf _NPROCESSORS_ONLN` + 2))
build \
    -n $NUM_CPUS \
    -a AARCH64 \
    -t GCC5 \
    -p edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc \
    -b RELEASE \
    --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVendor=L"rgl" \
    --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVersionString=L"UEFI Firmware RGL-CUSTOM" \
    -D SECURE_BOOT_ENABLE=TRUE \
    -D INCLUDE_TFTP_COMMAND=FALSE

# copy to the host.
# NB we also copy the Shell.efi file because its easier to use it
#    as a boot option. e.g. to add it as the last boot option to
#    reboot the system when all the other options have failed.
mkdir -p /vagrant/tmp
cp Build/RPi4/RELEASE_GCC5/FV/RPI_EFI.fd /vagrant/tmp/
cp Build/RPi4/RELEASE_GCC5/AARCH64/Shell.efi /vagrant/tmp/
ls -laF /vagrant/tmp/RPI_EFI.fd
