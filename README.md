# About

This is a [Vagrant](https://www.vagrantup.com/) Environment for a setting up
the [Raspberry Pi 4 UEFI EDK2](https://github.com/pftf/RPi4) environment.

## Usage

Install the [base Ubuntu 20.04 box](https://github.com/rgl/ubuntu-vagrant).

Start the environment:

```bash
time vagrant up --no-destroy-on-error
```

Then [flash the sd-card](#sd-card-flashing).

Then copy the generated files to the sd-card overriding the existing ones:

```bash
target=/media/$USER/RPI4-UEFI
install tmp/RPI_EFI.fd $target
install tmp/Shell.efi $target
install tmp/UiApp.efi $target
install -d $target/efi/boot
install tmp/ipxe.efi $target/efi/boot/bootaa64.efi
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
# NB after a successful build Build/RPi4/RELEASE_GCC5/FV/RPI_EFI.fd is
#    automatically copied to the host as /vagrant/tmp/RPI_EFI.fd.
time ./rpi4-uefi-build-release.sh
```

## iPXE

Build `ipxe.efi` (with the [rpi.ipxe](rpi.ipxe) embedded script):

```bash
vagrant ssh

# NB after a successful build ~/ipxe/src/bin-arm64-efi/ipxe.efi is
#    copied to the host as /vagrant/tmp/ipxe.efi.
time bash /vagrant/build-ipxe.sh

# return to the host shell.
exit
```

There are two ways to use iPXE:

1. Use it as the default UEFI boot application.
2. Configure UEFI to load it from an HTTP endpoint.

To use it as the default UEFI boot application, the file has to be
installed at `efi/boot/bootaa64.efi`:

```bash
install -d /media/$USER/RPI4-UEFI/efi/boot
install tmp/ipxe.efi /media/$USER/RPI4-UEFI/efi/boot/bootaa64.efi
```

To configure UEFI to load it from an HTTP endpoint, you need to
start an HTTP 1.1 server to serve `ipxe.efi`:

```bash
wget -O- https://github.com/caddyserver/caddy/releases/download/v2.3.0/caddy_2.3.0_linux_amd64.tar.gz | tar xzf - caddy
./caddy file-server --root tmp --listen :8000 --browse --access-log
```

**NB** We cannot simply use `python3 -m http.server 8000 -d tmp` because the
EDK2 HTTP client [assumes its talking to a HTTP/1.1 web server](https://bugzilla.tianocore.org/show_bug.cgi?id=2720),
but by default, the python server is configured in HTTP 1.0 mode.

Then power on the Raspberry Pi.

After it shows the UEFI boot prompt, press `ESC` to enter the EDK2 Setup,
then:

1. Select `Device Manager` and press `ENTER`.
2. Select `Network Device List` and press `ENTER`.
3. Select your network interface, e.g., `MAC:DC:A6:32:27:F5:46`, and
   press `ENTER`.
4. Select `HTTP Boot Configuration` and press `ENTER`.
5. Select `Boot URI` and press `ENTER`, then input the `ipxe.efi` url made
   available by the http server, e.g., `http://192.168.1.69:8000/ipxe.efi`,
   and press `ENTER`.
6. Press `F10` to save the changes.
7. Keep pressing `ESC` until you reach the main setup menu.
8. Select `Boot Manager`.
9. Select the entry created in 5 and press `ENTER`.

The Pi should download and start the `ipxe.efi` application.

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

## sd-card flashing

Find which device was allocated for the sd-card that will store the uefi firmware:

```bash
lsblk -o KNAME,SIZE,TRAN,FSTYPE,UUID,LABEL,MODEL,SERIAL
# lsblk should output all the plugged block devices, in my case, this is the device that I'm interested in:
#
#   sde    28,9G usb                                                                STORAGE DEVICE   000000078
#   sde1    256M        vfat   9F2D-0578                            boot
#   sde2    6,1G        ext4   efc2ea8b-042f-47f5-953e-577d8860de55 rootfs
```

Wipe the sd-card (in this example its at `/dev/sde`) and put the [pftf/RPi4 firmware](https://github.com/pftf/RPi4) in it:

**NB** the rpi4 `recovery.bin` (which will end up inside the eeprom) bootloader only
supports booting from an MBR/MSDOS partition type/table/label and from a
FAT32 LBA (0x0c) or FAT16 LBA (0x0e) partition types/filesystem. Eventually
[it will support GPT](https://github.com/raspberrypi/rpi-eeprom/issues/126).

**NB** the rpi4 bootloader that is inside the [mask rom](https://en.wikipedia.org/wiki/Mask_ROM) also [seems to support GPT](https://github.com/raspberrypi/rpi-eeprom/issues/126#issuecomment-628719223), but until its supported by `recovery.bin` we cannot use a GPT.

```bash
# switch to root.
sudo -i

# set the sd-card target device and mount point.
target_device=/dev/sde
target=/mnt/rpi4-uefi

# umount any existing partition that you might have already mounted.
umount ${target_device}?

# format the sd-card at $target_device.
parted --script $target_device mklabel msdos
parted --script $target_device mkpart primary fat32 4 100
parted $target_device print
# Model: Generic STORAGE DEVICE (scsi)
# Disk /dev/sde: 31,0GB
# Sector size (logical/physical): 512B/512B
# Partition Table: msdos
# Disk Flags:
#
# Number  Start   End     Size    Type     File system  Flags
#  1      4194kB  2048MB  2044MB  primary  fat32        lba
mkfs -t vfat -n RPI4-UEFI ${target_device}1

# install the firmware in the sd-card.
mkdir -p $target
mount ${target_device}1 $target
# get the rpi4 uefi firmware.
wget https://github.com/pftf/RPi4/releases/download/v1.22/RPi4_UEFI_Firmware_v1.22.zip
unzip RPi4_UEFI_Firmware_v1.22.zip -d $target
# add the drivers for the AX88179 gigabit ethernet chip.
# NB this is needed for my UGREEN USB 3.0 to RJ45 Ethernet Gigabit Lan Adapter.
#    see https://www.ugreen.com/products/usb-3-0-to-rj45-gigabit-ethernet-adapter
# NB this is needed because out-of-the-box edk2 only supports the chips at:
#      https://github.com/tianocore/edk2-platforms/tree/master/Drivers/OptionRomPkg/Bus/Usb/UsbNetworking
# See https://www.asix.com.tw/en/product/USBEthernet/Super-Speed_USB_Ethernet/AX88179
unzip drivers/AX88179_178A_UEFI_V2.8.0_ARM_AARCH64.zip -d $target

# setup the uefi shell to automatically load the driver.
# NB press F1 at the raspberry pi boot logo to enter the uefi shell
#    and automatically execute this startup.nsh script.
# RPi4_UEFI_Firmware_v1.22.zip ver is:
#       UEFI Interactive Shell v2.2
#       EDK II
#       UEFI v2.70 (https://github.com/pftf/RPi4, 0x00010000)
# see https://github.com/pftf/RPi4/issues/13
# see https://github.com/tianocore/tianocore.github.io/wiki/HTTP-Boot
# see https://uefi.org/sites/default/files/resources/UEFI_Shell_Spec_2_0.pdf
cat >$target/startup.nsh <<EOF
# set the terminal size.
mode 80 50 # make the terminal a bit taller.
mode       # show the available terminal modes.

# show the UEFI versions.
ver

# show the memory map.
memmap

# show the disks and filesystems.
map

# show the environment variables.
set

# show all UEFI variables.
#dmpstore

# show some rpi uefi variables.
# show the RAM Limit to 3 GB int32 (little endian) variable.
# possible values:
#   00 00 00 00: do not limit the ram to 3GB.
#   01 00 00 00: limit the ram to 3GB (default).
setvar -guid CD7CC258-31DB-22E6-9F22-63B0B8EED6B5 RamLimitTo3GB
# show the System Table Selection int32 (little endian) variable.
# possible values:
#   00 00 00 00: ACPI (default).
#   01 00 00 00: ACPI and DT.
#   02 00 00 00: DT.
setvar -guid CD7CC258-31DB-22E6-9F22-63B0B8EED6B5 SystemTableMode
# show the smbios asset tag string variable.
setvar -guid CD7CC258-31DB-22E6-9F22-63B0B8EED6B5 AssetTag

# change to the first filesystem and show its contents.
FS0:
dir

# load the network interface driver.
load FS0:\AX88179_178A_UEFI_V2.8.0_ARM_AARCH64\AX88179_178A_UEFI_V2.8.0_AARCH64.efi

# connect all the drivers to all the devices, recursively.
connect -r

# configure the network interface to use DHCP.
ifconfig -l
ifconfig -s eth0 dhcp # NB this starts the DHCP request in background.
# sleep 10s (10 followed by 6 zeros) and hope dhcp has worked.
@echo "waiting 10s to give dhcp time to come up..."
stall 10000000
ifconfig -l

# test pinging a machine in my network.
ping -n 4 192.168.1.69

# show more more information about drivers.
# the "drivers" command displays all the drivers, the AX88179 is normally the last one:
#               T   D
#   D           Y C I
#   R           P F A
#   V  VERSION  E G G #D #C DRIVER NAME                        IMAGE NAME
#   == ======== = = = == == ================================== ==========
#   A3 0000000A B - -  1  1 ASIX AX88179 Ethernet Driver 2.8.0 \AX88179_178A_UEFI_V2.8.0_AARCH64.efi
#drivers
#dh -d A3 -v # NB "A3" is the value of the first column "DRV".

# you can edit file with edit.
#edit FS0:\startup.nsh

# do not limit the ram to 3GB.
# NB this only applies after you reboot the pi with the reset command.
setvar -guid CD7CC258-31DB-22E6-9F22-63B0B8EED6B5 -bs -rt -nv RamLimitTo3GB =0x00000000
setvar -guid CD7CC258-31DB-22E6-9F22-63B0B8EED6B5 RamLimitTo3GB # show

# set the smbios asset tag.
# NB this has a maximum of 32-characters.
setvar -guid CD7CC258-31DB-22E6-9F22-63B0B8EED6B5 -bs -rt -nv AssetTag =L"PI00000001" =0x0000

@echo "TIP: Press the Page-Up key to see the terminal history"
EOF

# check the results.
find $target

# eject the sd-card.
umount $target
eject $target_device
```

## Reference

* https://github.com/pftf/RPi4/blob/v1.22/appveyor.yml
* https://github.com/pftf/RPi4/blob/v1.22/build_firmware.sh
* [UEFI Driver Writer's Guide](https://github.com/tianocore/tianocore.github.io/wiki/UEFI-Driver-Writer%27s-Guide)
* https://en.opensuse.org/UEFI_HTTPBoot_Server_Setup
  * https://patchwork.kernel.org/patch/9231147/
* https://github.com/pftf/RPi4/issues/13
* https://github.com/tianocore/tianocore.github.io/wiki/HTTP-Boot
* https://github.com/tianocore/edk2-platforms/tree/master/Drivers/OptionRomPkg/Bus/Usb/UsbNetworking
* https://github.com/tianocore/tianocore.github.io/wiki/ShellPkg
* http://www.uefi.org/sites/default/files/resources/UEFI_Shell_2_2.pdf

## Interesting projects

* https://github.com/andreiw/UefiToolsPkg
* https://github.com/bluebat/gnu-efi-applets
* https://github.com/chipsec/chipsec
