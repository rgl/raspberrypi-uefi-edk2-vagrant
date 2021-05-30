#!/bin/bash
set -euxo pipefail

# install the dependencies.
# see https://github.com/pftf/RPi4/blob/v1.27/.github/workflows/linux_edk2.yml
apt-get install -y \
    acpica-tools gcc-aarch64-linux-gnu python3-distutils uuid-dev \
    build-essential dos2unix
ln -s /usr/bin/python{3,} # symlink python to python3.

# clone the pftf flavor as it includes uptream edk2 as git sub-modules
# and build the base edk2 tools.
su vagrant -c bash <<'VAGRANT_EOF'
set -euxo pipefail

# clone the rpi4-uefi repo.
git clone https://github.com/pftf/RPi4 rpi4-uefi
cd rpi4-uefi
git checkout v1.27
git submodule update --init --recursive

# apply local patches.
patch --binary -d edk2 -p1 <0001-MdeModulePkg-UefiBootManagerLib-Signal-ReadyToBoot-o.patch

# install our build scripts.
install -m 644 /vagrant/rpi4-uefi-environment.sh .
install -m 755 /vagrant/rpi4-uefi-build-release.sh .

# build the base edk2 tools.
time make -C edk2/BaseTools
VAGRANT_EOF
