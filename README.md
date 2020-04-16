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

## Serial Console

Raspberry Pi 4B has two serial ports:

* PL011 UART (aka UART0/ttyAMA0)
* mini UART (aka UART1/ttyS0)

The `config.txt` file configures which of them is assigned to the
serial console GPIO pins 14 (TX) and 15 (RX).

The default configuration of the Raspberry Pi 4 UEFI EDK2 firmware
configures the serial console to use PL011 UART with:

```conf
enable_uart=1
uart_2ndstage=1
dtoverlay=miniuart-bt
```

For more information see:

* [Raspberry Pi Serial Console / UART](https://www.raspberrypi.org/documentation/configuration/uart.md)
* [miniuart-bt documentation](https://github.com/raspberrypi/firmware/blob/dd8cbec5a6d27090e5eb080e13d83c35fdd759f7/boot/overlays/README#L1691-L1702)

To access the serial console from your PC you normally use a
USB-to-SERIAL cable (3.3v). For example, the [adafruit cable](https://www.adafruit.com/product/954),
has four colored wires, which [must be connected as](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-5-using-a-console-cable/connect-the-lead):

| cable wire function | cable wire color | RPi GPIO      |
|---------------------|------------------|---------------|
| GND                 | black            | GND           |
| RX                  | white            | GPIO 14 / TX  |
| TX                  | green            | GPIO 15 / RX  |
| 5v                  | red              | NOT CONNECTED |

Then, in your PC, you can connect to the serial console with picocom:

```bash
sudo apt-get install -y picocom
# NB to quit picocom type Ctrl+A Ctrl+X.
# NB to use ESC key you have to press it once and wait a bit or
#    you need to press it twice.
# NB to send the F10 key you must prevent your terminal emulator
#    from using that key. in gnome, select the Edit menu,
#    Preferences, General tab and then unselect the Enable the
#    menu accelerator key option.
sudo picocom --baud 115200 /dev/ttyUSB0
```

Or, if you prefer, with minicom:

```bash
sudo apt-get install -y minicom
sudo tee /etc/minicom/minirc.rpi >/dev/null <<'EOF'
# NB use "minicom -s rpi" to change these default parameters.
pu port       /dev/ttyUSB0
pu baudrate   115200
pu bits       8
pu parity     N
pu stopbits   1
pu hasdcd     No    # disable DCD line detection.
pu rtscts     No    # disable hardware flow control.
pu xonxoff    No    # disable software flow control.
pu histlines  5000
EOF
# NB to quit minicom type Ctrl+A Q.
# NB minicom will say its offline when the usb-to-serial adaptor
#    does not support the Data Carrier Detect (DCD) line, and
#    even if it would, the RPi serial console pins do not have
#    support for it. so just ignore the offline message or change
#    the status line with the -F or --statlinefmt argument.
# NB to use ESC key you have to press it once and wait a bit or
#    you need to press it twice.
# NB to send the F10 key you must prevent your terminal emulator
#    from using that key. in gnome, select the Edit menu,
#    Preferences, General tab and then unselect the Enable the
#    menu accelerator key option.
# NB you can use --device=/dev/ttyUSBX to override the value
#    from minirc.rpi.
sudo minicom --color=on rpi
```

## Reference

* https://github.com/pftf/RPi4/blob/v1.8/appveyor.yml
* https://github.com/pftf/RPi4/blob/v1.8/build_firmware.sh

## Interesting projects

* https://github.com/andreiw/UefiToolsPkg
* https://github.com/bluebat/gnu-efi-applets
* https://github.com/chipsec/chipsec
