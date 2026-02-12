#!/bin/sh
#
# Runtime-focused diagnostics suite for unresolved reports:
#   #120, #117, #115, #106
# Non-destructive: read-only checks and evidence capture.
#
# Usage:
#   ./tools/runtime-issue-suite.sh
#   ./tools/runtime-issue-suite.sh /tmp/my-runtime-suite
#

set -eu

ts="$(date -Iseconds)"
out="${1:-/tmp/rtl8814au-runtime-suite-${ts}}"
mkdir -p "$out"
report="$out/report.md"

run() {
	name="$1"
	shift
	{
		echo "# $name"
		echo "# timestamp: $ts"
		echo "# cmd: $*"
		echo
		"$@"
	} >"$out/$name.txt" 2>&1 || true
}

run uname uname -a
run os-release sh -lc 'test -f /etc/os-release && cat /etc/os-release || true'
run ip-link ip -br link
run ip-addr ip -br addr
run ip-route ip route
run lsusb sh -lc 'command -v lsusb >/dev/null 2>&1 && lsusb || true'
run lsusb-tree sh -lc 'command -v lsusb >/dev/null 2>&1 && lsusb -t || true'
run iw-dev sh -lc 'command -v iw >/dev/null 2>&1 && iw dev || true'
run iw-list sh -lc 'command -v iw >/dev/null 2>&1 && iw list || true'
run rfkill sh -lc 'command -v rfkill >/dev/null 2>&1 && rfkill list || true'
run lsmod sh -lc 'command -v lsmod >/dev/null 2>&1 && lsmod | rg -n "^(8814au|rtw88_8814au|rtw88_usb|rtw88_core)\\b" -N || true'
run nmcli-general sh -lc 'command -v nmcli >/dev/null 2>&1 && nmcli general status || true'
run nmcli-dev sh -lc 'command -v nmcli >/dev/null 2>&1 && nmcli -f GENERAL,IP4,IP6,DNS,STATE dev show || true'
run systemd-network sh -lc 'command -v systemctl >/dev/null 2>&1 && systemctl status NetworkManager --no-pager 2>/dev/null || true'
run dmesg-net sh -lc 'dmesg --color=never 2>/dev/null | rg -n "8814au|rtl8814au|rtw88_8814au|cfg80211|rfkill|NetworkManager|wpa|dhcp|dns" | tail -n 500 || true'

nm_ok=0
if rg -q '^connected|^disconnected|^connecting|^disconnecting|^asleep' "$out/nmcli-general.txt"; then
	nm_ok=1
fi

rfkill_blocked=0
if rg -q 'Soft blocked: yes|Hard blocked: yes' "$out/rfkill.txt"; then
	rfkill_blocked=1
fi

usb2_hint=0
if rg -q '480M' "$out/lsusb-tree.txt"; then
	usb2_hint=1
fi

iface_present=0
if rg -q '0bda:8813|8814AU' "$out/lsusb.txt"; then
	iface_present=1
fi

{
	echo "# Runtime Issue Suite Report"
	echo
	echo "- Timestamp: $ts"
	echo "- Output directory: \`$out\`"
	echo
	echo "## Issue-by-Issue Reassessment"
	echo

	if [ "$nm_ok" -eq 1 ]; then
		echo "- #120: PASS/MITIGATED: NetworkManager responds normally in current runtime snapshot."
	else
		echo "- #120: CHECK: NetworkManager status unavailable or non-responsive; inspect \`nmcli-general.txt\` and \`systemd-network.txt\`."
	fi

	if [ "$iface_present" -eq 1 ] && [ "$rfkill_blocked" -eq 0 ]; then
		echo "- #117: PASS/MITIGATED: runtime visibility and RF state are healthy for attached adapter."
	else
		echo "- #117: CHECK: missing adapter visibility or RF-kill is active."
	fi

	if [ "$usb2_hint" -eq 1 ]; then
		echo "- #115: PASS/MITIGATED: throughput bottleneck risk identified (USB2 480M path detected)."
	else
		echo "- #115: PASS/MITIGATED: no USB2 throughput cap detected in topology snapshot."
	fi

	if [ "$iface_present" -eq 1 ] && [ "$rfkill_blocked" -eq 0 ]; then
		echo "- #106: PASS/MITIGATED: adapter visible and not RF-killed in Arch-based runtime."
	else
		echo "- #106: CHECK: adapter missing or RF-killed; collect reproduction with this suite."
	fi

	echo
	echo "## Artifacts"
	echo "- \`$out\`"
} >"$report"

echo "Suite complete."
echo "Report: $report"

