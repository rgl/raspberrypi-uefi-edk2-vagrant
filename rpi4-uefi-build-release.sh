#!/bin/bash
source rpi4-uefi-environment.sh
set -euxo pipefail

build \
    -a AARCH64 \
    -t GCC5 \
    -p edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc \
    -b RELEASE \
    --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVendor=L"rgl" \
    --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVersionString=L"UEFI Firmware RGL-CUSTOM" \
    -D SECURE_BOOT_ENABLE=TRUE \
    -D INCLUDE_TFTP_COMMAND=TRUE

ls -laF Build/RPi4/*_GCC5/FV/RPI_EFI.fd
