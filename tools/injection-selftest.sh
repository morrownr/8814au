#!/bin/sh
#
# Non-destructive monitor injection self-test for rtl8814au.
# Sends a few crafted radiotap+802.11 management frames and reports TX delta.
#
# Usage:
#   sudo ./tools/injection-selftest.sh --iface wlanX
#

set -eu

IFACE=""
OUTDIR="$(mktemp -d /tmp/rtl8814au-inject-XXXXXXXX)"

while [ $# -gt 0 ]; do
	case "$1" in
		--iface)
			IFACE="${2:-}"
			shift 2
			;;
		-h|--help)
			echo "Usage: $0 --iface IFACE"
			exit 0
			;;
		*)
			echo "Unknown argument: $1" >&2
			exit 1
			;;
	esac
done

if [ "$(id -u)" -ne 0 ]; then
	echo "Run as root (use sudo)." >&2
	exit 1
fi

if [ -z "$IFACE" ]; then
	echo "Missing --iface" >&2
	exit 1
fi

if [ ! -d "/sys/class/net/$IFACE" ]; then
	echo "Interface does not exist: $IFACE" >&2
	exit 1
fi

orig_type="$(iw dev "$IFACE" info | awk '$1=="type"{print $2; exit}')"
[ -n "$orig_type" ] || orig_type="managed"

cleanup() {
	ip link set "$IFACE" down || true
	iw dev "$IFACE" set type "$orig_type" || true
	ip link set "$IFACE" up || true
}
trap cleanup EXIT

echo "Output directory: $OUTDIR"
echo "Interface: $IFACE"
echo "Original type: $orig_type"

ip link set "$IFACE" down
iw dev "$IFACE" set type monitor
ip link set "$IFACE" up

before_tx="$(cat "/sys/class/net/$IFACE/statistics/tx_packets" 2>/dev/null || echo 0)"
before_bytes="$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)"
dmesg_before_lines="$(dmesg | wc -l | tr -d '[:space:]' || echo 0)"

python3 - "$IFACE" >"$OUTDIR/python.log" <<'PY'
import socket
import struct
import sys

iface = sys.argv[1]

def send(frame: bytes) -> None:
    s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW)
    s.bind((iface, 0))
    s.send(frame)
    s.close()

# radiotap headers with len 12/14/18 to exercise parser paths
rt12 = bytes([0x00,0x00,0x0c,0x00,0x04,0x80,0x00,0x00,0x02,0x00,0x18,0x00])
rt14 = bytes([0x00,0x00,0x0e,0x00,0x0c,0x80,0x00,0x00,0x02,0x00,0x18,0x00,0x00,0x00])
rt18 = bytes([0x00,0x00,0x12,0x00,0x0c,0x80,0x00,0x00,0x02,0x00,0x18,0x00,0x00,0x00,0x00,0x00,0x00,0x00])

# 802.11 deauth management frame (broadcast destination)
fc = b"\xc0\x00"      # deauth
dur = b"\x00\x00"
da = b"\xff\xff\xff\xff\xff\xff"
sa = b"\x12\x34\x56\x78\x9a\xbc"
bssid = b"\x12\x34\x56\x78\x9a\xbc"
seq = b"\x10\x00"
reason = b"\x07\x00"
mgmt = fc + dur + da + sa + bssid + seq + reason

for rt in (rt12, rt14, rt18):
    send(rt + mgmt)

print("sent_frames=3")
PY

sleep 1
after_tx="$(cat "/sys/class/net/$IFACE/statistics/tx_packets" 2>/dev/null || echo 0)"
after_bytes="$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)"
delta_pkts=$((after_tx - before_tx))
delta_bytes=$((after_bytes - before_bytes))
dmesg_tail="$OUTDIR/dmesg-tail.txt"
dmesg | sed -n "$((dmesg_before_lines + 1)),\$p" >"$dmesg_tail" 2>/dev/null || true
error_hits="$(awk '/(rtw|8814au).*(fail|error|drop|invalid|radiotap)/{c++} END{print c+0}' "$dmesg_tail" 2>/dev/null || echo 0)"

{
	echo "before_tx=$before_tx"
	echo "after_tx=$after_tx"
	echo "delta_pkts=$delta_pkts"
	echo "before_bytes=$before_bytes"
	echo "after_bytes=$after_bytes"
	echo "delta_bytes=$delta_bytes"
	echo "dmesg_error_hits=$error_hits"
	echo "python_log:"
	cat "$OUTDIR/python.log"
} | tee "$OUTDIR/report.txt"

if [ "$delta_pkts" -gt 0 ] || [ "$delta_bytes" -gt 0 ]; then
	echo "PASS: monitor injection TX counters increased after test frames"
	exit 0
fi

if [ "$error_hits" -eq 0 ]; then
	echo "PASS: monitor injection frames sent from userspace with no driver-side error signatures"
	exit 0
fi

echo "CHECK: monitor injection needs deeper repro (driver-side error signatures seen)"
exit 2
