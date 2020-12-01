### 8814au ( 8814au.ko )

### Linux Driver for the RealTek RTL8814AU Chipset.

- Driver Version: v5.8.5.1 (Realtek) (2019-10-29)
- Plus updates from the Linux community

### Features:

- IEEE 802.11 b/g/n/ac WiFi compliant

- Supported Ciphers:
	* WEP40 (00-0f-ac:1)
	* WEP104 (00-0f-ac:5)
	* TKIP (00-0f-ac:2)
	* CCMP-128 (00-0f-ac:4)
	* CMAC (00-0f-ac:6)

- Supported interface modes:
	* IBSS
	* Managed
	* AP (WiFi Hotspot) (Master mode)
	* Monitor
	* P2P-client
	* P2P-GO

- USB mode control
- Log level control
- LED control

### Compatible Kernels:

- Kernels: 2.6.24 - 5.2 (Realtek)
- Kernels: 5.3 - 5.9

### Tested Linux Distributions:

- Raspberry Pi OS (08-20-2020) (ARM 32 bit)

- LMDE 4 (Linux Mint based on Debian)

- Linux Mint 20 (Linux Mint based on Ubuntu)
- Linux Mint 19.3 (Linux Mint based on Ubuntu)

- Ubuntu 20.10
- Ubuntu 20.04
- Ubuntu 18.04

### Download Locations for Tested Linux Distributions:

- Raspberry Pi OS - https://www.raspberrypi.org/
- Linux Mint - https://linuxmint.com/
- Ubuntu - https://ubuntu.com/

### Tested Hardware:

- Wireless USB WiFi Adapter, 1900Mbps Dual Band 2.4GHz/600Mbps 5.8GHz/1300Mbps High Gain 5dBi Antennas USB 3.0
  ( https://www.amazon.com/gp/product/B07VCKN83P )

### Compatible Devices:

* D-Link DWA-192 AC1900 Ultra Wi-Fi USB 3.0 Adapter
* Numerous products that are based on the supported chipset


### Installation of the Driver:

Note: The installation instructions that are provided are for the novice user. Experienced users are welcome to alter the installation to meet their needs.

Note: The installation instructions require that your system has access to the internet. There are numerous ways to enable temporary internet access depending on your hardware and situation.

Note: The installation instructions require the use of the terminal. The quick way to open a terminal: Ctrl+Alt+T (hold down on the Ctrl and Alt keys then press the T key.)

Note: The installation instructions make use of DKMS. DKMS is a system utility which will automatically recompile and install this kernel module when a new kernel is installed. DKMS is provided by and maintained by Dell.

Note: It is recommended that you do not delete the driver directory after installation as the directory contains documentation (README.md) and scripts that you may need in the future.

Step 1: Open a terminal (Ctrl+Alt+T)

Step 2: Update the system:
```
$ sudo apt-get update
```
Step 3: Install the required packages: (select the option for the OS you are using)

Option for Raspberry Pi OS:
```
$ sudo apt-get install -y raspberrypi-kernel-headers bc build-essential dkms git
```
Option for LMDE (Debian based):
```
$ sudo apt-get install -y linux-headers-$(uname -r) build-essential dkms git
```
Option for Linux Mint or Ubuntu:
```
$ sudo apt-get install -y dkms git
```
Step 4: Create a directory to hold the downloaded driver:

Note: The technique used in this document is to create a directory in the home directory called `src`.
```
$ mkdir src
```
Step 5: Move to the newly created directory:
```
$ cd ~/src
```
Step 6: Download the driver:
```
$ git clone https://github.com/morrownr/8814au.git
```
Step 7: Move to the newly created driver directory:
```
$ cd ~/src/8814au
```
Step 8: Run the installation script and reboot: (select the option for the OS you are using)

Option for LMDE, Linux Mint or Ubuntu:

Run installation script and reboot:
```
$ sudo ./install-driver.sh
$ sudo reboot
```
Note: The installation for LMDE, Linux Mint or Ubuntu is complete.

Option for Raspberry Pi OS: (select either Option 1 or Option 2 but not both)

Turn off I386 support:
```
$ sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' Makefile
```
Option 1: for Raspberry Pi OS (32 bit), turn on ARM support:
```
$ sed -i 's/CONFIG_PLATFORM_ARM_RPI = n/CONFIG_PLATFORM_ARM_RPI = y/g' Makefile
```
Option 2: for Raspberry Pi OS (64 bit), turn on ARM64 support:
```
$ sed -i 's/CONFIG_PLATFORM_ARM64_RPI = n/CONFIG_PLATFORM_ARM64_RPI = y/g' Makefile
```
Run installation script and reboot:
```
$ sudo ./install-driver.sh
$ sudo reboot
```
Note: The installation for Raspberry Pi OS is complete.

### Removal of the Driver:

Step 1: Open a terminal (Ctrl+Alt+T)

Step 2: Move to the driver directory:
```
$ cd ~/src/8814au
```
Step 3: Run the removal script and reboot:
```
$ sudo ./remove-driver.sh
$ sudo reboot
```

### Driver Options:

A file called `8814au.conf` will be installed in `/etc/modeprob.d` by default.

Location: `/etc/modprobe.d/8814au.conf`

This file will be read and applied to the driver on each system boot.

To change the driver options, there are two options:

Option 1: Edit `8814au.conf` with a text editor using a terminal interface.

Example:
```
$ sudo nano /etc/modprobe.d/8814au.conf
```
Option 2: From the driver directory, run the `./edit-options.sh` script:
```
$ sudo ./edit-options.sh
```
The driver options are as follows:


USB mode options: ( rtw_switch_usb_mode )
```
  0 = no switch (default)
  1 = switch from usb 2.0 to usb 3.0
  2 = switch from usb 3.0 to usb 2.0
```
  Note: When changing USB options, a cold boot is recommended.


Log level options: ( rtw_drv_log_level )
```
  0 = NONE (default)
  1 = ALWAYS
  2 = ERRORS
  3 = WARNINGS
  4 = INFO
  5 = DEBUG
  6 = MAX
```
  Note: View RTW log entries by running the following in a terminal:
  ```
  $ sudo dmesg
  ```


LED control options: ( rtw_led_ctrl )
```
  0 = Always off
  1 = Normal blink (default)
  2 = Always on
```

### Information about USB 3 support:

USB 3 support is off by default as there can be problems with older USB 3 ports, however, almost all USB 3 ports on modern systems work well so turning USB 3 support on should work fine for almost everyone and the difference in performance can be large.

See what your USB mode is:

```
$ lsusb -t
```
```
USB 2 =  480M
USB 3 = 5000M
```
### iperf3 test results with USB 3 mode on:
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

### Entering Monitor Mode with 'iw' and 'ip':

Start by making sure the system recognizes the Wi-Fi interface:
```
$ sudo iw dev
```

Note: The output shows the Wi-Fi interface name and the current mode among other things. The interface name may be something like `wlx00c0cafre8ba` and is required for the below commands. The interface name `wlan0` will be used in the instructions below but you need to substitute your interface name.

Take the interface down:
```
$ sudo ip link set wlan0 down
```

Set monitor mode:
```
$ sudo iw wlan0 set monitor control
```

Bring the interface up:
```
$ sudo ip link set wlan0 up
```

Verify the mode has changed:
```
$ sudo iw dev
```

### Reverting to Managed Mode with 'iw' and 'ip':

Take the interface down:
```
$ sudo ip link set wlan0 down
```

Set managed mode:
```
$ sudo iw wlan0 set type managed
```

Bring the interface up:
```
$ sudo ip link set wlan0 up
```

Verify the mode has changed:
```
$ sudo iw dev
```

### ----------------------------- Various Tidbits of Information -----------------------------


### How to disable onboard WiFi on Raspberry Pi 3B, 3B+, 3A+, 4B and Zero W.

Add the following line to /boot/config.txt:
```
dtoverlay=disable-wifi
```


### How to forget a saved wifi network on a Raspberry Pi

1. Edit wpa_supplicant.conf:
```
$ sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
```
2. Delete the relevant wifi network block (including the 'network=' and opening/closing braces.

3. Press ctrl-x followed by 'y' and enter to save the file.

4. Reboot


### Recommended Router Settings for WiFi:

Note: These are general recommendations based on years of experience but may not apply to your situation so testing to see if any help fix your problem is recommended.

Security: Use WPA2-AES. Do not use WPA or WPA2 mixed mode or TKIP.

Channel Width for 2.4G: Use 20 MHz. Do not use 40 MHz or 20/40 automatic.

Channels for 2.4G: Use 1 or 6 or 11. Do not use automatic channel selection.

Mode for 2.4G: Use G/N or B/G/N. Do not use N only.

Network names: Do not set the 2.4G Network and the 5G Network to the same name. Many routers come with both networks set to the same name.

Power Saving: Set to off. This can help in some situations. If you try turning it off and you see no improvement then set it back to on so as to save electricity.

After making these changes, reboot the router.


### Set regulatory domain to correct setting in OS:

Check the current setting:
```
$ sudo iw reg get
```

If you get 00, that is the default and may not provide optimal performance.

Find the correct setting here: http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2

Set it temporarily:
```
$ sudo iw reg set US
```
Note: Substitute your country code if not the United States.

Set it permanently:
```
$ sudo nano /etc/default/crda

Change the last line to read:

REGDOMAIN=US
```
