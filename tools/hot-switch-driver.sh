#!/bin/sh
#
# Hot-switch RTL8814AU USB binding between in-kernel and out-of-tree drivers
# without reinstall/recompile/reboot. Captures pre/post snapshots for each step.
#
# Usage:
#   sudo ./tools/hot-switch-driver.sh --to native
#   sudo ./tools/hot-switch-driver.sh --to oot
#
# Optional:
#   --vidpid 0bda:8813
#   --outdir /tmp/rtl8814au-switch
#

set -eu

TARGET=""
VIDPID="0bda:8813"
OUTDIR=""

while [ $# -gt 0 ]; do
	case "$1" in
		--to)
			TARGET="${2:-}"
			shift 2
			;;
		--vidpid)
			VIDPID="${2:-}"
			shift 2
			;;
		--outdir)
			OUTDIR="${2:-}"
			shift 2
			;;
		-h|--help)
			echo "Usage: $0 --to native|oot [--vidpid VVVV:PPPP] [--outdir DIR]"
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

if [ -z "$TARGET" ]; then
	echo "Missing required --to native|oot" >&2
	exit 1
fi

case "$TARGET" in
	native)
		TARGET_DRIVER="rtw88_8814au"
		TARGET_MODULE="rtw88_8814au"
		;;
	oot)
		TARGET_DRIVER="rtl8814au"
		TARGET_MODULE="8814au"
		;;
	*)
		echo "--to must be 'native' or 'oot'" >&2
		exit 1
		;;
esac

if [ -z "$OUTDIR" ]; then
	OUTDIR="$(mktemp -d /tmp/rtl8814au-switch-XXXXXXXX)"
else
	if [ -e "$OUTDIR" ]; then
		echo "Output directory already exists: $OUTDIR" >&2
		exit 1
	fi
	mkdir -p "$OUTDIR"
fi

snap() {
	tag="$1"
	f="$OUTDIR/${tag}.txt"
	{
		echo "== snapshot:$tag =="
		date
		echo
		echo "== kernel =="
		uname -a
		echo
		echo "== lsusb =="
		lsusb || true
		echo
		echo "== lsusb -t =="
		lsusb -t || true
		echo
		echo "== module state =="
		lsmod | grep -E '^(8814au|rtw88_8814au|rtw88_usb|rtw88_core)\b' || true
		echo
		echo "== interfaces =="
		ip -br link || true
		echo
		echo "== iw dev =="
		iw dev || true
		echo
		echo "== bindings ($VIDPID) =="
		vid="${VIDPID%:*}"
		pid="${VIDPID#*:}"
		for d in /sys/bus/usb/devices/*; do
			[ -f "$d/idVendor" ] || continue
			v="$(cat "$d/idVendor" 2>/dev/null || true)"
			p="$(cat "$d/idProduct" 2>/dev/null || true)"
			[ "$v" = "$vid" ] || continue
			[ "$p" = "$pid" ] || continue
			echo "usb_dev:$d"
			for ifd in "${d}":*; do
				[ -d "$ifd" ] || continue
				drv="$(readlink -f "$ifd/driver" 2>/dev/null | awk -F/ '{print $NF}')"
				echo "  if=$(basename "$ifd") driver=${drv:-unbound}"
				for n in /sys/class/net/*; do
					[ -e "$n" ] || continue
					devp="$(readlink -f "$n/device" 2>/dev/null || true)"
					if [ "$devp" = "$(readlink -f "$ifd" 2>/dev/null || true)" ]; then
						echo "    netif=$(basename "$n")"
					fi
				done
			done
		done
	} >"$f"
	echo "snapshot -> $f"
}

resolve_iface() {
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
			echo "$(basename "$ifd")"
			return 0
		done
	done
	return 1
}

require_driver_node() {
	drv="$1"
	if [ ! -d "/sys/bus/usb/drivers/$drv" ]; then
		echo "Driver node not present: /sys/bus/usb/drivers/$drv" >&2
		return 1
	fi
	return 0
}

ensure_target_driver_node() {
	if require_driver_node "$TARGET_DRIVER"; then
		return 0
	fi

	# First try regular module resolution.
	modprobe "$TARGET_MODULE" 2>/dev/null || true
	if require_driver_node "$TARGET_DRIVER"; then
		return 0
	fi

	# Fallback for out-of-tree flow when module is built locally but not installed.
	if [ "$TARGET" = "oot" ]; then
		if [ -f "./8814au.ko" ]; then
			insmod ./8814au.ko 2>/dev/null || true
		elif [ -f "../8814au.ko" ]; then
			insmod ../8814au.ko 2>/dev/null || true
		fi
	fi

	require_driver_node "$TARGET_DRIVER"
}

current_driver_for_iface() {
	iface="$1"
	readlink -f "/sys/bus/usb/devices/$iface/driver" 2>/dev/null | awk -F/ '{print $NF}'
}

snap "00-pre"

IFACE_ID="$(resolve_iface || true)"
if [ -z "$IFACE_ID" ]; then
	echo "No USB interface found for $VIDPID" >&2
	exit 1
fi
echo "Resolved USB interface: $IFACE_ID"

CUR_DRIVER="$(current_driver_for_iface "$IFACE_ID" || true)"
echo "Current bound driver: ${CUR_DRIVER:-unbound}"
echo "Target driver: $TARGET_DRIVER"

ensure_target_driver_node

if [ "$CUR_DRIVER" = "$TARGET_DRIVER" ]; then
	echo "Already bound to target driver; no switch needed."
	snap "01-noop-already-target"
	echo "Snapshots stored in: $OUTDIR"
	exit 0
fi

if [ -n "$CUR_DRIVER" ] && [ -e "/sys/bus/usb/drivers/$CUR_DRIVER/unbind" ]; then
	snap "10-before-unbind"
	echo "$IFACE_ID" >"/sys/bus/usb/drivers/$CUR_DRIVER/unbind"
	snap "11-after-unbind"
fi

snap "20-before-modprobe-target"
modprobe "$TARGET_MODULE" 2>/dev/null || true
ensure_target_driver_node
snap "21-after-modprobe-target"

if [ ! -e "/sys/bus/usb/drivers/$TARGET_DRIVER/bind" ]; then
	echo "Target driver bind path not found: /sys/bus/usb/drivers/$TARGET_DRIVER/bind" >&2
	exit 1
fi

snap "30-before-bind-target"
echo "$IFACE_ID" >"/sys/bus/usb/drivers/$TARGET_DRIVER/bind"
snap "31-after-bind-target"

NEW_DRIVER="$(current_driver_for_iface "$IFACE_ID" || true)"
echo "Final bound driver: ${NEW_DRIVER:-unbound}"

if [ "$NEW_DRIVER" != "$TARGET_DRIVER" ]; then
	echo "Switch did not bind expected driver ($TARGET_DRIVER)." >&2
	echo "See snapshots in: $OUTDIR" >&2
	exit 1
fi

echo "Switch success. Snapshots stored in: $OUTDIR"
