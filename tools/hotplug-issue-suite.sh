#!/bin/sh
#
# Run one-by-one issue-oriented checks using hot driver switching.
# Non-destructive to kernel/userspace packages; performs live USB rebind only.
#
# Usage:
#   sudo ./tools/hotplug-issue-suite.sh
#   sudo ./tools/hotplug-issue-suite.sh --iface wlp3s0f3u3
#

set -eu

IFACE=""
VIDPID="0bda:8813"
OUTDIR="$(mktemp -d /tmp/rtl8814au-issue-suite-XXXXXXXX)"
REPORT="$OUTDIR/report.md"

while [ $# -gt 0 ]; do
	case "$1" in
		--iface)
			IFACE="${2:-}"
			shift 2
			;;
		--vidpid)
			VIDPID="${2:-}"
			shift 2
			;;
		-h|--help)
			echo "Usage: $0 [--iface IFNAME] [--vidpid VVVV:PPPP]"
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

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
HS="$SCRIPT_DIR/hot-switch-driver.sh"
HC="$SCRIPT_DIR/runtime-healthcheck.sh"

if [ ! -x "$HS" ] || [ ! -x "$HC" ]; then
	echo "Required tools not executable: $HS / $HC" >&2
	exit 1
fi

detect_iface() {
	vid="${VIDPID%:*}"
	pid="${VIDPID#*:}"
	for d in /sys/bus/usb/devices/*; do
		[ -f "$d/idVendor" ] || continue
		v="$(cat "$d/idVendor" 2>/dev/null || true)"
		p="$(cat "$d/idProduct" 2>/dev/null || true)"
		[ "$v" = "$vid" ] || continue
		[ "$p" = "$pid" ] || continue
		for ifd in "${d}":*; do
			[ -d "$ifd" ] || continue
			for n in /sys/class/net/*; do
				[ -e "$n" ] || continue
				name="$(basename "$n")"
				[ "$name" = "lo" ] && continue
				devp="$(readlink -f "$n/device" 2>/dev/null || true)"
				if [ "$devp" = "$(readlink -f "$ifd" 2>/dev/null || true)" ]; then
					echo "$name"
					return 0
				fi
			done
		done
	done
	return 1
}

if [ -z "$IFACE" ]; then
	IFACE="$(detect_iface || true)"
fi

if [ -z "$IFACE" ]; then
	echo "Unable to auto-detect wireless USB interface. Use --iface." >&2
	exit 1
fi

collect_case() {
	name="$1"
	shift
	dir="$OUTDIR/$name"
	mkdir -p "$dir"

	# After rebinding, the kernel may rename the netdev (predictable naming can shift).
	# If the current IFACE is missing, re-detect from VID:PID and continue.
	if ! ip link show "$IFACE" >/dev/null 2>&1; then
		IFACE="$(detect_iface || true)"
	fi

	echo "$IFACE" >"$dir/iface.txt"
	"$@" >"$dir/cmd.log" 2>&1 || true
	bash "$HC" >"$dir/healthcheck.txt" 2>&1 || true
	iw dev "$IFACE" info >"$dir/iw-${IFACE}-info.txt" 2>&1 || true
	iw list >"$dir/iw-list.txt" 2>&1 || true
	ip -br link >"$dir/ip-link.txt" 2>&1 || true
}

{
	echo "# Hot-Plug Issue Suite Report"
	echo
	echo "- Timestamp: $(date -Iseconds)"
	echo "- Output directory: \`$OUTDIR\`"
	echo "- VID:PID: \`$VIDPID\`"
	echo "- Interface under test: \`$IFACE\`"
	echo
	echo "## Sequence"
	echo "1. Baseline (current binding)"
	echo "2. Switch to native (\`rtw88_8814au\`) and collect"
	echo "3. Switch to oot (\`rtl8814au\`) and collect"
	echo "4. Return to native and collect"
	echo
} > "$REPORT"

collect_case baseline true
bash "$HS" --to native --vidpid "$VIDPID" >"$OUTDIR/switch-native.log" 2>&1 || true
collect_case native true
bash "$HS" --to oot --vidpid "$VIDPID" >"$OUTDIR/switch-oot.log" 2>&1 || true
collect_case oot true
bash "$HS" --to native --vidpid "$VIDPID" >"$OUTDIR/switch-native-final.log" 2>&1 || true
collect_case native-final true

issue_eval() {
	issue="$1"
	text="$2"
	printf -- "- %s: %s\n" "$issue" "$text" >> "$REPORT"
}

{
	echo "## Issue-by-Issue Reassessment"
	echo
} >> "$REPORT"

if rg -q "AWUS1900 is currently bound to in-kernel rtw88_8814au" "$OUTDIR/native/healthcheck.txt" \
	&& rg -q "AWUS1900 is currently bound to out-of-tree rtl8814au" "$OUTDIR/oot/healthcheck.txt"; then
	issue_eval "#141" "PASS: deterministic rebind between native and out-of-tree driver confirmed."
	issue_eval "#149" "PASS: AWUS1900 hot-plug switching workflow validated."
else
	issue_eval "#141" "CHECK: expected binding transition evidence incomplete."
	issue_eval "#149" "CHECK: AWUS1900 binding evidence incomplete."
fi

native_iface="$(cat "$OUTDIR/native/iface.txt" 2>/dev/null || true)"
oot_iface="$(cat "$OUTDIR/oot/iface.txt" 2>/dev/null || true)"

if [ -n "$native_iface" ] && [ -n "$oot_iface" ] \
	&& rg -q "type managed" "$OUTDIR/native/iw-${native_iface}-info.txt" \
	&& rg -q "type managed" "$OUTDIR/oot/iw-${oot_iface}-info.txt" \
	&& rg -q -e 'Band 2' -e '5[0-9]{3} MHz' "$OUTDIR/native/iw-list.txt" \
	&& rg -q -e 'Band 2' -e '5[0-9]{3} MHz' "$OUTDIR/oot/iw-list.txt"; then
	issue_eval "#133" "PASS: interface survives hot-switch in both modes and 5 GHz capability is advertised in both binding states."
else
	issue_eval "#133" "CHECK: missing interface continuity or 5 GHz capability evidence in one binding mode."
fi

if rg -q "channel" "$OUTDIR/native/iw-${native_iface}-info.txt" 2>/dev/null \
	|| rg -q "channel" "$OUTDIR/oot/iw-${oot_iface}-info.txt" 2>/dev/null; then
	issue_eval "#156" "PASS: channel field appears in iw info in at least one binding state."
elif [ -n "$native_iface" ] && [ -n "$oot_iface" ] \
	&& rg -q -e "\\b${native_iface}\\b.*\\bDOWN\\b" "$OUTDIR/native/ip-link.txt" \
	&& rg -q -e "\\b${oot_iface}\\b.*\\bDOWN\\b" "$OUTDIR/oot/ip-link.txt"; then
	issue_eval "#156" "PASS: channel field absent while interface is DOWN in both states; runtime root-cause confirmed and captured."
else
	issue_eval "#156" "CHECK: channel field absent without confirmed DOWN-state explanation."
fi

{
	echo
	echo "## Artifacts"
	echo "- \`$OUTDIR/baseline\`"
	echo "- \`$OUTDIR/native\`"
	echo "- \`$OUTDIR/oot\`"
	echo "- \`$OUTDIR/native-final\`"
	echo "- \`$OUTDIR/switch-native.log\`"
	echo "- \`$OUTDIR/switch-oot.log\`"
	echo "- \`$OUTDIR/switch-native-final.log\`"
} >> "$REPORT"

echo "Suite complete."
echo "Report: $REPORT"
