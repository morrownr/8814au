#!/bin/sh
#
# Collect DNS + link evidence for reports like upstream issue #102.
# Read-only: does not change NetworkManager/systemd-resolved configuration.
#
# Usage:
#   ./tools/dns-diagnose.sh
#   sudo ./tools/dns-diagnose.sh
#

set -eu

ts="$(date -Iseconds)"
out="${1:-/tmp/rtl8814au-dns-diagnose-${ts}}"
mkdir -p "$out"

write() {
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

write uname uname -a
write os-release sh -lc 'test -f /etc/os-release && cat /etc/os-release || true'
write ip-link ip -br link
write ip-addr ip -br addr
write ip-route ip route

write resolv-conf sh -lc 'ls -l /etc/resolv.conf || true; echo; cat /etc/resolv.conf 2>/dev/null || true'
write resolvectl sh -lc 'command -v resolvectl >/dev/null 2>&1 && resolvectl status || true'
write systemd-resolved sh -lc 'systemctl status systemd-resolved --no-pager 2>/dev/null || true'

write nmcli-dev sh -lc 'command -v nmcli >/dev/null 2>&1 && nmcli -f GENERAL,IP4,IP6,DNS,STATE dev show || true'
write nmcli-con sh -lc 'command -v nmcli >/dev/null 2>&1 && nmcli -f NAME,UUID,TYPE,DEVICE,STATE con show --active || true'
write nm-status sh -lc 'systemctl status NetworkManager --no-pager 2>/dev/null || true'

write ping-ip sh -lc 'ping -c 2 -W 2 1.1.1.1 || true'
write ping-dns sh -lc 'ping -c 2 -W 2 google.com || true'

write dig sh -lc 'command -v dig >/dev/null 2>&1 && dig +time=2 +tries=1 google.com A || true'
write drill sh -lc 'command -v drill >/dev/null 2>&1 && drill -t A google.com || true'
write nslookup sh -lc 'command -v nslookup >/dev/null 2>&1 && nslookup google.com || true'

write journal-nm sh -lc 'journalctl -u NetworkManager --since "1 hour ago" --no-pager 2>/dev/null | tail -n 400 || true'
write journal-resolved sh -lc 'journalctl -u systemd-resolved --since "1 hour ago" --no-pager 2>/dev/null | tail -n 400 || true'
write dmesg-net sh -lc 'dmesg --color=never 2>/dev/null | rg -n \"8814au|rtl8814au|cfg80211|wpa|dhcp|dns|resolv\" | tail -n 300 || true'

echo "Wrote: $out"
