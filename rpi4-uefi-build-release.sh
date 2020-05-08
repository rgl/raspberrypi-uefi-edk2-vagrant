#!/bin/bash
source rpi4-uefi-environment.sh
set -euxo pipefail

# build.
build \
    -a AARCH64 \
    -t GCC5 \
    -p edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc \
    -b RELEASE \
    --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVendor=L"rgl" \
    --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVersionString=L"UEFI Firmware RGL-CUSTOM" \
    -D SECURE_BOOT_ENABLE=TRUE \
    -D INCLUDE_TFTP_COMMAND=TRUE

# copy to the host.
mkdir -p /vagant/tmp
cp Build/RPi4/RELEASE_GCC5/FV/RPI_EFI.fd /vagrant/tmp/
ls -laF /vagrant/tmp/RPI_EFI.fd
