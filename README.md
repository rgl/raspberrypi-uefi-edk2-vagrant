# About

This is a [Vagrant](https://www.vagrantup.com/) Environment for a setting up
the [Raspberry Pi 4 UEFI EDK2](https://github.com/pftf/RPi4) environment.

## Usage

Install the [base Ubuntu 18.04 box](https://github.com/rgl/ubuntu-vagrant).

Start this environment:

```bash
time vagrant up
```

Enter the environment and build `RPI_EFI.fd`:

```bash
vagrant ssh

# build the release version of RPI_EFI.fd.
cd rpi4-uefi
time ./rpi4-uefi-build-release.sh

# copy the resulting firmware image to the host.
install -d /vagrant/tmp
cp Build/RPi4/RELEASE_GCC5/FV/RPI_EFI.fd /vagrant/tmp
```

Then flash the sd-card as described at https://gist.github.com/rgl/95b8ccd6b3453f548907b579d4d04a72.

Then copy `tmp/RPI_EFI.fd` to the sd-card overriding the existing file:

```bash
install tmp/RPI_EFI.fd /media/$USER/RPI4-UEFI
```

## Reference

* https://github.com/pftf/RPi4/blob/da46a6e91715f1b6f15d1c7c9aa49de6337c62d9/appveyor.yml
* https://github.com/pftf/RPi4/blob/da46a6e91715f1b6f15d1c7c9aa49de6337c62d9/build_firmware.sh

## Interesting projects

* https://github.com/andreiw/UefiToolsPkg
* https://github.com/bluebat/gnu-efi-applets
* https://github.com/chipsec/chipsec
