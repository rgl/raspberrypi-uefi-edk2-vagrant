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

## Switching sub-modules repositories/branches

You can switch to a different sub-module repository/branch. For example,
to switch the `edk2-platforms` submodule do:

```bash
git submodule foreach --recursive 'git branch -v'
git submodule foreach --recursive 'git status'
git config --file=.gitmodules submodule.edk2-platforms.url https://github.com/samerhaj/edk2-platforms.git
git config --file=.gitmodules submodule.edk2-platforms.branch ASIX_USB_Networking
git submodule sync edk2-platforms
git submodule update --init --recursive --remote edk2-platforms
git submodule foreach --recursive 'git branch -v'   # you should check if it has the expected commit id.
git submodule foreach --recursive 'git status'      # it should say: nothing to commit, working tree clean.
```

Clean and build:

```bash
rm -rf Build
time ./rpi4-uefi-build-release.sh
cp Build/RPi4/RELEASE_GCC5/FV/RPI_EFI.fd /vagrant/tmp
```

## EDK2 Notes

* The build is described by the `edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc` file.
* A component/module is only built when the `.dsc` file references the `.inf` file, e.g.:
  the `.dsc` has something alike:
    ```ini
    [Components.common]
        # ...
        Drivers/OptionRomPkg/Bus/Usb/UsbNetworking/Ax88179/Ax88179.inf
    ```
* A component/module is only included in the firmware image when the
  `edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.fdf` file references the `.inf` file,
  e.g.: the `.fdf` file has something alike:
    ```ini
    [FV.FvMain]
        # ...
        INF Drivers/OptionRomPkg/Bus/Usb/UsbNetworking/Ax88179/Ax88179.inf
    ```

## Reference

* https://github.com/pftf/RPi4/blob/da46a6e91715f1b6f15d1c7c9aa49de6337c62d9/appveyor.yml
* https://github.com/pftf/RPi4/blob/da46a6e91715f1b6f15d1c7c9aa49de6337c62d9/build_firmware.sh

## Interesting projects

* https://github.com/andreiw/UefiToolsPkg
* https://github.com/bluebat/gnu-efi-applets
* https://github.com/chipsec/chipsec
