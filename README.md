##### [Click for USB WiFi Adapter Information for Linux](https://github.com/morrownr/USB-WiFi)

-----

### 8814au ( 8814au.ko ) :rocket:

### Linux Driver for USB WiFi Adapters that are based on the RTL8814AU Chipset

- v5.8.5.1 (Realtek) (2019-10-29)
- Plus updates from the Linux community

### Features

- IEEE 802.11 b/g/n/ac WiFi compliant
- 802.1x, WEP, WPA TKIP and WPA2 AES/Mixed mode for PSK and TLS (Radius)
- WPS - PIN and PBC Methods
- IEEE 802.11b/g/n/ac Client mode
  * Support wireless security for WEP, WPA TKIP and WPA2 AES PSK
  * Support site survey scan and manual connect
  * Support WPA/WPA2 TLS client
  * Support power saving mode
- Soft AP mode
- WiFi-Direct
- MU-MIMO
- Mesh
- Wake on WLAN
- Supported interface modes:
  * IBSS
  * Managed (client)
  * AP (see *Bridged Wireless Access Point* located in the main directory of this repo)
  * Monitor (see *Monitor_Mode.md* located in the main directory of this repo)
  * P2P-client
  * P2P-GO
- USB mode control
- Log level control
- LED control
- Power saving control
- VHT control (allows 80 MHz channel width in AP mode)

Note: WPA3-AES does not appear to be working. If you need a comparable adapter
that does support WPA3-AES, I will suggest an Alfa AWUS036ACM. You can get more
information and links about this adapter at the following site-

https://github.com/morrownr/USB-WiFi

### Compatible CPUs

- x86, amd64
- ARM, ARM64

### Compatible Kernels

- Kernels: 2.6.24 - 5.2 (Realtek)
- Kernels: 5.3 - 5.12

### Tested Linux Distributions

- Arch Linux (kernel 5.4)
- Arch Linux (kernel 5.9)

- Linux Mint 20.1 (Linux Mint based on Ubuntu) (kernel 5.4)
- Linux Mint 20   (Linux Mint based on Ubuntu) (kernel 5.4)
- Linux Mint 19.3 (Linux Mint based on Ubuntu) (kernel 5.4)

- LMDE 4 (Linux Mint based on Debian) (kernel 4.19)

- Manjaro 20.1 (kernel 5.9)

- Raspberry Pi OS (2021-01-11) (ARM 32 bit) (kernel 5.10)
- Raspberry Pi Desktop (x86 32 bit) (kernel 4.9)

- Ubuntu 20.10 (kernel 5.8)
- Ubuntu 20.04 (kernel 5.4)
- Ubuntu 18.04 (kernel 5.4)

### Download Locations for Tested Linux Distributions

- [Arch Linux](https://www.archlinux.org)
- [Linux Mint](https://www.linuxmint.com)
- [Manjaro](https://manjaro.org)
- [Raspberry Pi OS](https://www.raspberrypi.org)
- [Ubuntu](https://www.ubuntu.com)

### Tested Hardware

- [Wireless USB WiFi Adapter, 1900Mbps Dual Band 2.4GHz/600Mbps 5.8GHz/1300Mbps High Gain 5dBi Antennas USB 3.0]( https://www.amazon.com/gp/product/B07VCKN83P )

- [ASUS USB-AC68 AC1900 Dual-Band USB 3.0 WiFi Adapter](https://www.amazon.com/dp/B01I7QFR10)

### Compatible Devices

Warning: Beware of "multi-state" USB WiFi adapters. Some USB WiFi adapters have proprietary Windows drivers onboard. When plugged in, they act like a flash drive or CDROM and on Windows will attempt to start installing the Windows driver. That won't work on Linux or MAC or any other non-Windows OS so the adapter sits there in flash drive or CDROM mode. The problem is that the state of the adapter has to be changed for the adapter to show up as the device that you expect, in this case, a WiFi adapter. Most modern Linux distributions ship with a utility called "usb-modeswitch" that will handle this issue for you if it has the correct information for your adapter. It is a good utility but if you buy adapters that are "multi-state," that is one more potential headache you may have to deal with when something goes wrong. Often you can indentify adapters that are "multi-state" as they are advertised as "free driver" or "free installation driver." If you are looking to buy a USB WiFi adapter for use on Linux, MAC OS, *NIX or anything besides Windows, it is a good idea to seek out single-state adapters.

Note: Some adapter makers change the chipsets in their products while keeping the same model number so please check to confirm that the product you plan to buy has the chipset you are expecting.

* D-Link DWA-192 AC1900 Ultra Wi-Fi USB 3.0 Adapter
* ASUS USB-AC68 AC1900 Dual-Band USB 3.0 WiFi Adapter
* Edimax EW-7833 UAC AC1750 Dual-Band Wi-Fi USB 3.0 Adapter
* Numerous products that are based on the supported chipset

### Installation Information

The installation instructions are for the novice user. Experienced users are welcome to alter the installation to meet their needs.

Temporary internet access is required for installation. There are numerous ways to enable temporary internet access depending on your hardware and situation. [One method is to use tethering from a phone.](https://www.makeuseof.com/tag/how-to-tether-your-smartphone-in-linux)

Another method to enable temporary internet access is to keep a [wifi adapter that uses an in-kernel driver](https://github.com/morrownr/USB-WiFi) in your toolkit.

You will need to use the terminal interface. The quick way to open a terminal: Ctrl+Alt+T (hold down on the Ctrl and Alt keys then press the T key)

DKMS is used for the installation. DKMS is a system utility which will automatically recompile and install this driver when a new kernel is installed. DKMS is provided by and maintained by Dell.

It is recommended that you do not delete the driver directory after installation as the directory contains information and scripts that you may need in the future.

### Installation Steps

Step 1: Open a terminal (Ctrl+Alt+T)

Step 2: Update the system (select the option for the OS you are using)
```
    Option for Debian based distributions such as Ubuntu, Linux Mint and the Raspberry Pi OS

    $ sudo apt-get update
```
```
    Option for Arch based distributions such as Manjaro

    $ sudo pacman -Syu
```
Step 3: Install the required packages (select the option for the OS you are using)
```
    Option for Raspberry Pi OS

    $ sudo apt-get install -y raspberrypi-kernel-headers bc build-essential dkms git
```
```
    Option for LMDE (Debian based)

    $ sudo apt-get install -y linux-headers-$(uname -r) build-essential dkms git
```
```
    Option for Linux Mint or Ubuntu (all flavors)

    $ sudo apt-get install -y dkms git
```
```
    Option for Arch based distributions such as Manjaro

    $ sudo pacman -S --noconfirm linux-headers dkms git
```
Step 4: Create a directory to hold the downloaded driver

```bash
$ mkdir src
```
Step 5: Move to the newly created directory
```bash
$ cd ~/src
```
Step 6: Download the driver
```bash
$ git clone https://github.com/morrownr/8814au.git
```
Step 7: Move to the newly created driver directory
```bash
$ cd ~/src/8814au
```
Step 8: Run a preparation script if required (Raspberry Pi *hardware* requires a preparation script)
```
    Option for 32 bit operating systems to be installed to Raspberry Pi hardware

    $ sudo ./raspi32.sh
```
```
    Option for 64 bit operating systems to be installed to Raspberry Pi hardware

    $ sudo ./raspi64.sh
```
Step 9: Run the installation script
```bash
$ sudo ./install-driver.sh
```
Step 10: Reboot
```bash
$ sudo reboot
```

### Driver Options

A file called `8814au.conf` will be installed in `/etc/modeprob.d` by default.

`/etc/modprobe.d/8814au.conf`

This file will be read and applied to the driver on each system boot.

To edit the driver options file, run the `edit-options.sh` script.
```bash
$ sudo ./edit-options.sh
```
The driver options are as follows

 -----

 Log level options ( rtw_drv_log_level )
```
 0 = NONE (default)
 1 = ALWAYS
 2 = ERROR
 3 = WARNING
 4 = INFO
 5 = DEBUG
 6 = MAX
```
 Note: You can save a log of RTW log entries by running the following in a terminal:

 $ sudo ./save-log.sh

 -----

 LED control options ( rtw_led_ctrl )
```
 0 = Always off
 1 = Normal blink (default)
 2 = Always on
```
 -----

 VHT enable options ( rtw_vht_enable )
```
  0 = Disable
  1 = Enable (default)
  2 = Force auto enable (use caution)
```
 Notes:
 - Unless you know what you are doing, don't change the default for rtw_vht_enable.
 - A non-default setting can degrade performance greatly in some operational modes.
 - For AP mode, such as when you are using Hostapd, setting this option to 2 will
   allow 80 MHz channel width.

 -----

  Power saving options ( rtw_power_mgnt )
```
 0 = Disable power saving
 1 = Power saving on, minPS (default)
 2 = Power saving on, maxPS
```
 Note: 0 may be useful in unattended server setups or if dropouts are experienced.

 -----

 USB mode options ( rtw_switch_usb_mode )
```
 0 = No switch (default)
 1 = Switch from usb 2.0 to usb 3.0
 2 = Switch from usb 3.0 to usb 2.0
```
 Note: When changing USB options, a cold boot is recommended.

 -----

### Information about USB 3 support

USB 3 support is off by default as there can be problems with older USB 3 ports, however, almost all USB 3 ports on modern systems work well so turning USB 3 support on should work fine for almost everyone and the difference in performance can be large.

See what your USB mode is:

```bash
$ lsusb -t
```
```
USB 2 =  480 Mb/s
USB 3 = 5000 Mb/s
```

### iperf3 test results with USB 3 mode on
```
Bitrate
-------------
590 Mbits/sec
596 Mbits/sec
599 Mbits/sec
624 Mbits/sec
629 Mbits/sec
607 Mbits/sec
607 Mbits/sec
616 Mbits/sec
611 Mbits/sec
```
### Removal of the Driver

Step 1: Open a terminal (Ctrl+Alt+T)

Step 2: Move to the driver directory
```bash
$ cd ~/src/8814au
```
Step 3: Run the removal script
```bash
$ sudo ./remove-driver.sh
```
Step 4: Reboot
```bash
$ sudo reboot
```
### Recommended Router Settings for WiFi

Note: These are general recommendations, some of which may not apply to your specific situation.

Security: Set WPA2-AES (or WPA2-AES/WPA3-SAE mixed mode if available.) Do not set WPA2 mixed mode or WPA or TKIP.

Channel width for 2.4G: Set 20 MHz fixed width. Do not use 40 MHz or 20/40 automatic.

Channels for 2.4G: Set channel 1 or 6 or 11 depending on the congestion at your location. Do not set automatic channel selection.

Mode for 2.4G: Set N only if you no longer use B or G capable devices.

Network names: Do not set the 2.4G Network and the 5G Network to the same name. Note: Unfortunately many routers come with both networks set to the same name.

Channels for 5G: Not all devices are capable of using DFS channels. It may be necessary to set channel 36 or 149 fixed depending on the congestion at your location.

Best location for the router: Near center of apartment or house, at least a couple of feet away from walls, in an elevated location.

Checking congestion: There are apps available for smart phones that allow you to check the congestion levels on wifi channels. The apps generally go by the name of WiFi Analyzer or something similar.

After making and saving changes, reboot the router.


### Set regulatory domain to correct setting in OS

Check the current setting
```bash
$ sudo iw reg get
```

If you get 00, that is the default and may not provide optimal performance.

Find the correct setting here: http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2

Set it temporarily
```bash
$ sudo iw reg set US
```
Note: Substitute your country code if you are not in the United States.

Set it permanently
```bash
$ sudo nano /etc/default/crda

Change the last line to read:

REGDOMAIN=US
```

### Recommendations regarding USB

- If connecting your USB WiFi adapter to a desktop computer, use the USB ports on the rear of the computer. Why? The ports on the rear are directly connected to the motherboard which will reduce problems with interference and disconnection that can happen with front ports that use cables.

- If your USB WiFi adapter is USB 3 capable then plug it into a USB 3 port.

- If you use an extension cable and your adapter is USB 3 capable, the cable needs to be USB 3 capable.

- Some USB WiFi adapters require considerable electrical current and push the capabilities of the power available via USB port. One example is devices that use the Realtek 8814au chipset. Using a powered multiport USB extension can be a good idea in cases like this.


### How to disable onboard WiFi on Raspberry Pi 3B, 3B+, 3A+, 4B and Zero W.

Add the following line to /boot/config.txt
```
dtoverlay=disable-wifi
```

### How to forget a saved WiFi network on a Raspberry Pi

1. Edit wpa_supplicant.conf
```bash
$ sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
```
2. Delete the relevant WiFi network block (including the 'network=' and opening/closing braces.

3. Press ctrl-x followed by 'y' and enter to save the file.

4. Reboot
