<img align="left" src="https://raw.githubusercontent.com/joseguzman1337/8814au/main/Gemini_Generated_Image_v0p2mpv0p2mpv0p2.png" width="140">

# 8814au

**Linux Driver for USB WiFi Adapters based on the RTL8814AU Chipset**

[![license](https://img.shields.io/badge/license-GPL-brightgreen.svg)](https://github.com/joseguzman1337/8814au/blob/main/LICENSE) ![kernel](https://img.shields.io/badge/kernel-5.4--6.18.x-blue.svg) ![arch](https://img.shields.io/badge/arch-x86__64%20%7C%20arm%20%7C%20arm64-orange.svg) ![dkms](https://img.shields.io/badge/DKMS-supported-purple.svg)

Actively maintained fork of [morrownr/8814au](https://github.com/morrownr/8814au). USB WiFi driver for RTL8814AU-based adapters supporting kernels 5.4–6.18.x, Feb 2026.

<br clear="left">

---

## Supported Features

<details>
<summary><b>WiFi capabilities</b> — 802.11 b/g/n/ac, security, interface modes</summary>

| Feature | Details |
|:---|:---|
| Standards | IEEE 802.11 b/g/n/ac |
| Security | 802.1x, WEP, WPA TKIP, WPA2 AES/Mixed (PSK & TLS/Radius) |
| Client Mode | Site survey, manual connect, power saving |
| Interface Modes | Managed, Monitor, AP |
| Controls | Log level, LED, power saving, VHT (80 MHz AP), USB mode |

</details>

<details>
<summary><b>Compatible CPU architectures</b></summary>

| Architecture | Variants |
|:---|:---|
| x86 | i386, i686 |
| x86-64 | amd64 |
| ARM | armv6l, armv7l |
| ARM64 | aarch64 |

</details>

<details>
<summary><b>Compatible devices</b></summary>

| Device |
|:---|
| ALFA AWUS1900 |
| ASUS USB-AC68 AC1900 Dual-Band USB 3.0 WiFi Adapter |
| Edimax EW-7833 UAC AC1750 Dual-Band Wi-Fi USB 3.0 Adapter |
| COMFAST CF-958AC |
| Numerous adapters based on the RTL8814AU chipset |

See `supported-device-IDs` for full list.

</details>

---

## Installation

<details>
<summary><b>Arch / Garuda / Manjaro</b> — pacman + DKMS</summary>

```bash
sudo pacman -S --noconfirm linux-headers dkms git bc iw
git clone https://github.com/joseguzman1337/8814au.git
cd 8814au
sudo ./install-driver.sh
```

Note: If using Manjaro on RasPi4B/5B, use `linux-rpi4-headers` instead.

</details>

<details>
<summary><b>Ubuntu / Debian / Kali</b> — apt</summary>

```bash
sudo apt install -y linux-headers-$(uname -r) build-essential bc dkms git libelf-dev rfkill iw
git clone https://github.com/joseguzman1337/8814au.git
cd 8814au
sudo ./install-driver.sh
```

For Kali on RasPi4B/5B, use `kalipi-kernel-headers` instead of `linux-headers-$(uname -r)`.

</details>

<details>
<summary><b>Fedora / CentOS</b> — dnf</summary>

```bash
sudo dnf -y install git dkms kernel-devel
git clone https://github.com/joseguzman1337/8814au.git
cd 8814au
sudo ./install-driver.sh
```

</details>

<details>
<summary><b>openSUSE</b> — zypper</summary>

```bash
sudo zypper install -t pattern devel_kernel dkms
git clone https://github.com/joseguzman1337/8814au.git
cd 8814au
sudo ./install-driver.sh
```

</details>

<details>
<summary><b>Raspberry Pi OS</b> — apt</summary>

```bash
sudo apt install -y raspberrypi-kernel-headers build-essential bc dkms git
git clone https://github.com/joseguzman1337/8814au.git
cd 8814au
sudo ./install-driver.sh
```

</details>

<details>
<summary><b>Void Linux</b> — xbps</summary>

```bash
sudo xbps-install linux-headers dkms git make
git clone https://github.com/joseguzman1337/8814au.git
cd 8814au
sudo ./install-driver.sh
```

</details>

<details>
<summary><b>Manual installation</b> — without install script</summary>

```bash
make clean
make
sudo make install    # if Secure Boot is OFF
sudo make sign-install  # if Secure Boot is ON
sudo reboot
```

To remove:

```bash
sudo make uninstall
sudo reboot
```

Note: Manual installs must be repeated after each kernel upgrade. Use `install-driver.sh` with DKMS for automatic rebuilds.

</details>

<details>
<summary><b>Secure Boot</b> — MOK enrollment</summary>

If Secure Boot is active, after `sudo make sign-install` you will be prompted for a password. On reboot:

1. MOK management screen appears → **Enroll key** → **Continue** → **Yes**
2. Enter the password from the install step

Fedora users may also need:

```bash
sudo mokutil --import /var/lib/dkms/mok.pub
```

See `FAQ.md` for more details.

</details>

---

## Driver Options

<details>
<summary><b>Configuration</b> — runtime options via modprobe.d</summary>

The install script places `8814au.conf` in `/etc/modprobe.d/`. Edit with:

```bash
sudo ./edit-options.sh
```

Documentation for all options is included in `8814au.conf`.

</details>

---

## Upgrading & Removal

<details>
<summary><b>Upgrade</b> — pull latest and reinstall</summary>

```bash
cd ~/src/8814au
sudo ./remove-driver.sh
git pull
sudo ./install-driver.sh
```

</details>

<details>
<summary><b>Remove</b> — uninstall driver</summary>

```bash
cd ~/src/8814au
sudo ./remove-driver.sh
```

</details>

---

## WiFi Router Recommendations

<details>
<summary><b>Best practices</b> — security, channels, placement</summary>

| Setting | Recommendation |
|:---|:---|
| Security | WPA2-AES, WPA2/WPA3 mixed, or WPA3 — avoid WPA/TKIP |
| 2.4 GHz Width | 20 MHz fixed — avoid 40 MHz or auto |
| 2.4 GHz Channel | 1, 6, or 11 (check local congestion) — avoid auto |
| 2.4 GHz Mode | N-only if no legacy B/G devices remain |
| 5 GHz Channel | 36–48 or 149–165 for broadest device compat (US) |
| Network Names | Use different SSIDs for 2.4 GHz and 5 GHz |
| Router Placement | Centered, elevated, away from walls |

</details>

<details>
<summary><b>USB tips</b></summary>

- Try different USB ports if you encounter issues (rear ports preferred on desktops)
- Use USB 3.0 ports for USB 3 adapters
- Avoid USB 3.1 Gen 2 ports — most adapters tested with Gen 1 only
- Extension cables must match USB version; test without cable if issues arise
- RTL8814AU adapters draw significant power — a powered USB hub may help

</details>

---

## Tested Distributions

<details>
<summary><b>Community-verified distros</b></summary>

| Distribution | Kernel(s) |
|:---|:---|
| Arch Linux | 5.4, 5.11, 6.6 |
| Debian | 5.10, 5.15, 6.1, 6.6 |
| Fedora 38 | 6.2 |
| Manjaro | 5.15 |
| openSUSE Tumbleweed | 5.15 |
| Raspberry Pi OS | 2023-12-05 (ARM 32/64) |
| Ubuntu 22.04 / 22.10 | 5.15, 5.19, 6.2, 6.5 |
| Void Linux | 5.18 |

Kernels 5.4–6.18.x supported. Compilers: gcc 12, 13, 14.

</details>

---

<p align="center">
  Original project by <a href="https://github.com/morrownr">@morrownr</a><br>
  Fork maintained by <a href="https://github.com/joseguzman1337">@joseguzman1337</a> & <a href="https://claude.ai">Claude</a>
</p>
