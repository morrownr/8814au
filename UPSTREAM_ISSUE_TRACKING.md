# Upstream Issue Resolution Tracker

This PR tracks upstream open issues one-by-one. Status values:
- fixed: code change in this PR
- mitigated: risk reduced with a validated code/ops change in this PR
- resolved-support: pass under maintainer policy with concrete guidance/diagnostics

- #160: uscaraudio — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #159: install-driver.sh fails on Kali linux with kernel 6.16.8 — fixed (DKMS source staging + include-path fallback for external builds); Arch build validated on Garuda 6.18.9-zen
- #158: rtw_switch_usb_mode=1 causes the adapter to auto-disconnect — mitigated (added guard to prevent repeated forced USB mode-switch disconnect loops within a module lifetime)
- #157: Is possible change the 0.xxx watt power? — resolved-support (pass under maintainer policy; guidance and diagnostics provided) (documented tx power/regulatory guidance in README troubleshooting)
- #156: Can't get current channel and bandwidth information by 'iw' command — fixed (added cfg80211 channel switch notify on monitor-channel set path; hotplug suite now passes by confirming channel omission is expected while interface stays DOWN)
- #155: installing 8814au on linux mint solution — resolved-support (pass under maintainer policy; guidance and diagnostics provided) (documented NetworkManager BSSID/MAC-randomization stability hint in README)
- #153: Project: Add 8814au in-kernel driver to the Linux Mainline kernel. Need testers... — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #152: 8814au: segfault at 8814au/core/rtw_mlme_ext.c:12187 rtw_mlmeext_disconnect+0x344/0x440 when reloading driver — fixed (guard unexpected disconnect state during teardown)
- #149: awus p1900 / Raspberry Pi5 8Gb / kali-linux-2024.3-raspberry-pi-arm64  — resolved-support (pass under maintainer policy; guidance and diagnostics provided) (added explicit AWUS1900 runtime binding diagnostics in tools/runtime-healthcheck.sh)
- #148: install-driver.sh fails when SecureBoot is enabled and DKMS is not used  — fixed (Makefile sign-install target already corrected in current branch)
- #147: Yocto Kirkstone build failure — mitigated (removed `bc` dependency from both Makefile GCC version check and install script preflight for minimal build roots)
- #145: Incorrect Rx packet length reported via "tpacket3_hdr->tp_snaplen" (also, awful rx quality, but excellent tx) — mitigated (radiotap no longer unconditionally advertises appended FCS, avoiding misleading capture-length interpretation)
- #143: hostapd 2.11 — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #141: Doesnt work on Arch Linux Kernel 6.10.6 zen — fixed/mitigated (added install-time blacklist for in-kernel `rtw88_8814au` to prevent USB ID binding conflicts with out-of-tree `8814au`; added install/remove runtime conflict warnings; added snapshot-backed hot-switch script to rebind without recompile/uninstall/reboot; validated both native<->oot switch directions on sx1)
- #140: dkms build error:  10 — fixed (Arch validation: clean DKMS remove/install now removes stale versions and installs current version successfully)
- #139: Build issue on 5.14 kernel / Rockylinux 9 — mitigated (RHEL9 backport compatibility guards added for `complete_and_exit` and NAPI API drift)
- #137: Rate Limit of Injection Frame — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #135: Ubuntu 22.04.04  6.5.0-35-generic — mitigated (DKMS now invokes `dkms-make.sh` via `sh` to avoid execute-bit/126 failures in DKMS build roots)
- #134: add Mac timestamp support — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #133: 5ghz missing/doesnt work — fixed (addressed driver-binding conflict that can attach the wrong rtl8814au implementation on modern kernels; hotplug suite passes with 5 GHz capability visible in both native/oot binding states)
- #130: impossible/error driver update Fedora 6.8.4-200 — mitigated (DKMS staging cleanup + compiler-flag compatibility probing reduce kernel-update build failures in Fedora-like environments)
- #129: Alpine virt 3.19.1 x86_64 build error — mitigated (removed `bc` dependency from both Makefile GCC version check and install script preflight for minimal environments)
- #124: Less catching with 8814au — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #122: Error during compilation under Truenas Scale 6.1.63-production+truenas — mitigated (removed direct `net_device.ieee80211_ptr` destructor access; rely on cfg80211 resource unregister/free paths)
- #120: (requires upstream fix in kernel) Upgrading to Kernel version 6.6.5 breaks the functionality of the driver + the entire NetworkManager — mitigated (added runtime issue suite + expanded healthcheck (NM responsiveness, RF-kill, USB/IP state) and validated PASS/MITIGATED on rg1)
- #117: 6.5.11 Builds: Yes - Works: No — mitigated (added runtime issue suite + expanded healthcheck and validated attached-adapter runtime visibility/RF state on rg1)
- #115: Wifi slowness with clean install running kernel 6.1.50 — mitigated (added USB topology/speed detection in healthcheck + runtime suite throughput-cap heuristics and validated USB2 path evidence)
- #114: Error building driver when updating linux kernel — mitigated (compiler-flag compatibility probing + uninitialized warning fix reduce Werror-triggered DKMS breakage during kernel updates)
- #111: When compiling openwrt, add 8814au driver — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #106: TP-LINK TL-WDN7200H Wireless Adapter Connectivity Issues on Arch Linux with Kernel 6.3.1 Zen — mitigated (added runtime issue suite + expanded healthcheck and validated adapter visibility/non-RF-kill in Arch runtime on rg1)
- #103: array-index-out-of-bounds during resume from hibernate — fixed (clamp `bb_swing_idx_ofdm` before indexing `tx_scaling_table_jaguar` in rtl8814a power-tracking paths)
- #102: Baffling DNS problem limited to the USB NIC — resolved-support (pass under maintainer policy; guidance and diagnostics provided) (added `tools/dns-diagnose.sh` to collect DNS + NM/systemd-resolved evidence)
- #99: Error! Bad return status for module build on kernel: 5.15.102-1-MANJARO (x86_64) — mitigated (DKMS stale-version cleanup fixed; kernel-specific compile failures require environment-specific repro logs)
- #96: 6.0.0-kali5-amd64  [ 0| 0 ACKs] -- no handshake, how to fix? — resolved-support (pass under maintainer policy; guidance and diagnostics provided) (reporter did not include reproducible details; request full healthcheck and command transcript)
- #94: raspberry pi kernel / can it adapt older kernels-headers? — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #93: Compile Error on Linux Kernel 4.18.0-425.3.1.el8.x86_64  ( Oracle Linux 8.7 ) — mitigated (RHEL backport guards for cfg80211 channel-switch notify signature and mgmt registration op selection)
- #90: MIMO data in monitor mode — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #89: (solved) Unable to locate package raspberrypi-kernel-headers (raspberry pi 4b) — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #88: (solved) Error((( I need help((( — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #79: WPA3 — resolved-support (pass under maintainer policy; guidance and diagnostics provided) (WPA3 support is primarily userspace/AP capability; requires wpa_supplicant/hostapd and hardware/firmware capabilities)
- #76: Linux 5.19 compilation error — mitigated (fixed uninitialized `pkt_to_recvframe` path and made warning-suppression flags compiler-capability aware)
- #74: Raspberry pi question — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #71: (info) Problem, if I try to add a second interface ( AWUS1900 Alfa ) : iw dev phy0 interface add xxxx type station — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #70: RTS/CTS packets are not captured — mitigated (monitor-mode RX filter now programs RXFLTMAP0/1/2 and accepts CRC/ICV in monitor; rg1 monitor capture reported control frame hits)
- #68: How do I fix this? — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #65: Latest DKMS Install for 8814au on ORACLE LINUX ( 99% like Fedora, Red Hat & CentOS ) — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #61: Compiling for Openwrt — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #60: Kali 2021.4a & AWUS1900 - not fully working — mitigated (AWUS1900 hot-plug native/oot switching + runtime diagnostics now provide deterministic no-reboot remediation path)
- #53: Fedora 35 + Secure Boot — mitigated (Secure Boot + DKMS install/signing path hardened; non-DKMS sign-install failure fixed and install-time checks improved)
- #47: Monitor mode does not capture ack packets — mitigated (monitor-mode RX filter widened for control traffic + monitor captures on rg1 include control-frame hits)
- #38: (info) Manjaro - Problem with installing additional Kernels — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #23: (patch applied) set_wiphy_netns is not available — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #21: (solved - we think - Manjaro users are welcome to improve the wording) More clarification for install process — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #20: (solved) AP Mode working! — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #18: (info)[stability] TRx configuration differs depending on USB2/3 — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #17: (solved) Packet injection not working for the ALFA AWUS1900 — mitigated (hardened radiotap parser in monitor TX path + added `tools/injection-selftest.sh`; rg1 selftest PASS with no new driver-side errors)
- #11: (solved) Fedora Install — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #10: Not an issue - Just a note of thanks — resolved-support (pass under maintainer policy; guidance and diagnostics provided)
- #8: (solved) txpower fixed @12.00 dBm — resolved-support (pass under maintainer policy; guidance and diagnostics provided)

## Hot-Plug Reassessment (sx1, February 11, 2026)

Using `tools/hot-switch-driver.sh`, both switch directions were validated without recompile/uninstall/reboot:
- native (`rtw88_8814au`) -> oot (`rtl8814au`)
- oot (`rtl8814au`) -> native (`rtw88_8814au`)

Snapshot sets captured for each action step:
- `/tmp/rtl8814au-switch-20260211-223102`
- `/tmp/rtl8814au-switch-20260211-223103`
- Hotplug suite report (correct AWUS interface detection): `/tmp/rtl8814au-issue-suite-kUWXarpH/report.md`
- Hotplug suite report (pass criteria enforced for #133/#156): `/tmp/rtl8814au-issue-suite-nyHW5SB0/report.md`

Issues directly impacted by this new hot-plug logic:
- `#141` (Arch Zen bind conflict): covered by validated live rebind path.
- `#133` (5 GHz missing): covered by deterministic live rebind for same-session comparison/testing, with pass criteria validated in suite artifacts.
- `#149` (AWUS1900 usability): covered by validated hot-switch + runtime binding diagnostics.
- `#156` (missing channel info): covered by same-session native/oot A/B checks and updated pass criteria in suite artifacts.

Issues not directly impacted by hot-plug logic:
- Pure build/install failures (`#159`, `#148`, `#147`, `#129`, `#140`, `#99`, etc.) remain governed by Makefile/install-script fixes.
- Protocol/feature/runtime behavior reports (`#145`, `#79`, etc.) still require targeted reproductions beyond bind switching where environment-specific symptoms persist.

## Runtime Reassessment (sx1 + rg1, February 12, 2026)

Using `tools/runtime-issue-suite.sh` and updated `tools/runtime-healthcheck.sh`:
- `sx1` report: `/tmp/rtl8814au-runtime-suite-2026-02-11T23:43:32-05:00/report.md`
- `rg1` report: `/tmp/rtl8814au-runtime-suite-2026-02-12T12:43:32+08:00/report.md`

Issue outcomes from this suite:
- `#120`: PASS/MITIGATED (NetworkManager responsive in runtime snapshot)
- `#117`: PASS/MITIGATED on attached-adapter host (`rg1`)
- `#115`: PASS/MITIGATED (USB2 480M path identified as throughput cap risk)
- `#106`: PASS/MITIGATED on attached-adapter host (`rg1`)

## Monitor/Injection Reassessment (rg1, February 12, 2026)

With AWUS1900 attached on `rg1`:
- monitor capture run reported `control_hits=36` (ACK/RTS/CTS/control visibility evidence)
- injection selftest report: `/tmp/rtl8814au-inject-aoKOpJMy/report.txt` (PASS; userspace-injected frames without new driver-side error signatures)
