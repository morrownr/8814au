## Bridged Wireless Access Point

A bridged wireless access point setup works within an existing
ethernet network to extend the network to WiFi capable computers
and devices in areas where the WiFi signal is weak or otherwise
does not meet expectations.

Known issues:

- WPA3-SAE operation is not testing good at this time and is disabled.
- 80 MHz channel width causes problems in some setups and is disabled.

This document is for WiFi adapters based on the following chipset
```
rtl8814au

```
Note: Recommend use of a powered USB 3 hub when using adapters with
this chipset as it uses a lot of power.

2021-02-20

##### Tested Setup

- Raspberry Pi 4B (4gb)

- Raspberry Pi OS (2021-01-11) (32 bit) (kernel 5.10.11-v7l+)

- Raspberry Pi Onboard WiFi disabled

- USB WiFi Adapter based on the rtl8814au chipset

- WiFi Adapter Driver - https://github.com/morrownr/8814au

- Ethernet connection providing internet
	- Ethernet cables are CAT 6
	- Internet is Fiber-optic at 1 Gbps up and 1 Gbps down

##### Steps

1. Disable Raspberry Pi onboard WiFi.

Note: Disregard this step if not installing to Raspberry Pi hardware.
```
$ sudo nano /boot/config.txt
```
Add
```
dtoverlay=disable-wifi
```
-----

2. Install the driver for the WiFi adapter.

Follow the instructions at this site

https://github.com/morrownr/8814au

-----

3. Change driver options (to allow high speed operation.)

```
$ sudo nano /etc/modprobe.d/8814au.conf
```
```
rtw_switch_usb_mode=1 (enable USB 3 support)
```
Note: You may try to use the following setting once you have a
stable setup going but I consider it to be unstable on this
device at this time.
```
rtw_vht_enable=2      (enable 80 Mhz channel width)
```

-----

4. Update system.
```
$ sudo apt update

$ sudo apt full-upgrade

$ sudo reboot
```
-----

5. Install needed package.
```
$ sudo apt install hostapd
```
-----

6. Enable the wireless access point service and set it to start
   when your Raspberry Pi boots.
```
$ sudo systemctl unmask hostapd

$ sudo systemctl enable hostapd
```
-----

7. Add a bridge network device named br0 by creating a file using
   the following command, with the contents below.
```
$ sudo nano /etc/systemd/network/bridge-br0.netdev
```
File contents
```
[NetDev]
Name=br0
Kind=bridge
```
-----

8. Determine the names of the network interfaces.
```
$ ip link show
```
Note: If the interface names are not eth0 and wlan0, then the
interface names used in your system will have to replace eth0
and wlan0 during the remainder of this document.

-----

9. Bridge the Ethernet network with the wireless network, first
   add the built-in Ethernet interface ( eth0 ) as a bridge
   member by creating the following file.
```
$ sudo nano /etc/systemd/network/br0-member-eth0.network
```
File contents
```
[Match]
Name=eth0

[Network]
Bridge=br0
```
-----

10. Enable the systemd-networkd service to create and populate
    the bridge when your Raspberry Pi boots.
```
$ sudo systemctl enable systemd-networkd
```
-----

11. Block the eth0 and wlan0 interfaces from being
    processed, and let dhcpcd configure only br0 via DHCP.
```
$ sudo nano /etc/dhcpcd.conf
```
Add the following line above the first interface xxx line, if any
```
denyinterfaces wlan0 eth0
```
Go to the end of the file and add the following line
```
interface br0
```
-----

12. To ensure WiFi radio is not blocked on your Raspberry Pi,
    execute the following command.
```
$ sudo rfkill unblock wlan
```
-----

13. Create the hostapd configuration file.
```
$ sudo nano /etc/hostapd/hostapd.conf
```
File contents
```
# /etc/hostapd/hostapd.conf
# https://w1.fi/hostapd/
# 2g, 5g, a/b/g/n/ac
# 2021-02-20

# Needs to match your system
interface=wlan0

bridge=br0
driver=nl80211
ctrl_interface=/var/run/hostapd
#ctrl_interface_group=0

# Change as desired
ssid=pi

# Change as required
country_code=US

# Enable DFS channels
#ieee80211d=1
#ieee80211h=1

# 2g (b/g/n)
#hw_mode=g
#channel=6
#
# 5g (a/n/ac)
hw_mode=a
channel=36
# channel=149

beacon_int=100
dtim_period=1
max_num_sta=32
macaddr_acl=0
ignore_broadcast_ssid=0
rts_threshold=2347
fragm_threshold=2346
send_probe_response=1

# Security
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_pairwise=CCMP
# Change as desired
wpa_passphrase=raspberry
# WPA-2 AES
wpa_key_mgmt=WPA-PSK WPA-PSK-SHA256
# WPA-3 SAE
#wpa_key_mgmt=SAE
wpa_group_rekey=1800
rsn_pairwise=CCMP
# ieee80211w=2 is required for WPA-3 SAE
#ieee80211w=2
# If parameter is not set, 19 is the default value.
#sae_groups=19 20 21 25 26
#sae_require_mfp=1
# If parameter is not 9 set, 5 is the default value.
#sae_anti_clogging_threshold=10

# IEEE 802.11n
# 2g and 5g
ieee80211n=1
#
# Note: Capabilities can vary even between adapters with the same chipset.
#
# 20 MHz channel width (recommended for use with 2g channels)
ht_capab=[SHORT-GI-20][MAX-AMSDU-7935]
#
# 40 MHz channel width for use with 5g if desired
#ht_capab=[HT40+][HT40-][SHORT-GI-20][SHORT-GI-40][MAX-AMSDU-7935][DSSS_CCK-40]

# IEEE 802.11ac
# 5g
ieee80211ac=1
#
# Note: Capabilities can vary even between adapters with the same chipset.
#
vht_capab=[MAX-MPDU-11454][SHORT-GI-80][TX-STBC-2BY1][SU-BEAMFORMEE][HTC-VHT]

# The next line is required for 80 MHz width channel operation
#vht_oper_chwidth=1
#
# Use the next line with channel 36
#vht_oper_centr_freq_seg0_idx=42
#
# Use the next with channel 149
#vht_oper_centr_freq_seg0_idx=155

# Event logger
#logger_syslog=-1
#logger_syslog_level=2
#logger_stdout=-1
#logger_stdout_level=2

# WMM
wmm_enabled=1
#uapsd_advertisement_enabled=1
#wmm_ac_bk_cwmin=4
#wmm_ac_bk_cwmax=10
#wmm_ac_bk_aifs=7
#wmm_ac_bk_txop_limit=0
#wmm_ac_bk_acm=0
#wmm_ac_be_aifs=3
#wmm_ac_be_cwmin=4
#wmm_ac_be_cwmax=10
#wmm_ac_be_txop_limit=0
#wmm_ac_be_acm=0
#wmm_ac_vi_aifs=2
#wmm_ac_vi_cwmin=3
#wmm_ac_vi_cwmax=4
#wmm_ac_vi_txop_limit=94
#wmm_ac_vi_acm=0
#wmm_ac_vo_aifs=2
#wmm_ac_vo_cwmin=2
#wmm_ac_vo_cwmax=3
#wmm_ac_vo_txop_limit=47
#wmm_ac_vo_acm=0

# TX queue parameters
#tx_queue_data3_aifs=7
#tx_queue_data3_cwmin=15
#tx_queue_data3_cwmax=1023
#tx_queue_data3_burst=0
#tx_queue_data2_aifs=3
#tx_queue_data2_cwmin=15
#tx_queue_data2_cwmax=63
#tx_queue_data2_burst=0
#tx_queue_data1_aifs=1
#tx_queue_data1_cwmin=7
#tx_queue_data1_cwmax=15
#tx_queue_data1_burst=3.0
#tx_queue_data0_aifs=1
#tx_queue_data0_cwmin=3
#tx_queue_data0_cwmax=7
#tx_queue_data0_burst=1.5

# end of hostapd.conf
```
-----

14. Establish conf file and log file locations.
```
$ sudo nano /etc/default/hostapd
```
Add to bottom of file
```
DAEMON_CONF="/etc/hostapd/hostapd.conf"
DAEMON_OPTS="-d -K -f /home/pi/hostapd.log"
```
-----

15. Reboot the system.

$ sudo reboot

-----

16. Enjoy!

-----

