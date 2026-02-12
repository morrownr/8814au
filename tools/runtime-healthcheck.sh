#!/bin/sh
#
# Non-invasive runtime diagnostics for 8814au/rtw88 conflicts and channel visibility.
# This script is read-only: it does not load/unload modules or change network state.

set -eu

echo "== Host =="
uname -a
echo

echo "== USB devices (RTL8814AU candidates) =="
if command -v lsusb >/dev/null 2>&1; then
	lsusb | grep -Ei '0bda:8813|8814au' || echo "No RTL8814AU USB device detected by lsusb"
else
	echo "lsusb not available"
fi
echo

echo "== USB topology/speed hint =="
if command -v lsusb >/dev/null 2>&1; then
	lsusb -t 2>/dev/null || true
	echo "Hint: 5000M indicates USB3; 480M indicates USB2 and can cap throughput."
else
	echo "lsusb not available"
fi
echo

echo "== USB binding detail (0bda:8813) =="
if [ -d /sys/bus/usb/devices ]; then
	found_usb=0
	awus_bound_native=0
	awus_bound_oot=0
	for d in /sys/bus/usb/devices/*; do
		[ -f "$d/idVendor" ] || continue
		v="$(cat "$d/idVendor" 2>/dev/null || true)"
		p="$(cat "$d/idProduct" 2>/dev/null || true)"
		[ "$v" = "0bda" ] || continue
		[ "$p" = "8813" ] || continue
		found_usb=1
		echo "Device node: $d"
		# interface nodes (e.g. 2-3:1.0) hold the effective driver binding
		for ifd in "${d}":*; do
			[ -d "$ifd" ] || continue
			drv="$(readlink -f "$ifd/driver" 2>/dev/null | awk -F/ '{print $NF}')"
			echo "  Interface $(basename "$ifd") driver: ${drv:-unbound}"
			[ "${drv:-}" = "rtw88_8814au" ] && awus_bound_native=1
			[ "${drv:-}" = "rtl8814au" ] && awus_bound_oot=1
		done
	done
	[ "$found_usb" -eq 1 ] || echo "No 0bda:8813 USB node found in /sys"
else
	echo "/sys/bus/usb/devices not available on this host"
fi
echo

echo "== RF-kill state =="
if command -v rfkill >/dev/null 2>&1; then
	rfkill list || true
else
	echo "rfkill not available"
fi
echo

echo "== Module state =="
if command -v lsmod >/dev/null 2>&1; then
	lsmod | grep -E '^(8814au|rtw88_8814au|rtw88_usb|rtw88_core)\b' || echo "No 8814au/rtw88 modules currently loaded"
else
	echo "lsmod not available"
fi
echo

echo "== USB/IP forwarding state =="
if command -v usbip >/dev/null 2>&1; then
	usbip port 2>/dev/null || echo "No imported USB/IP devices on this host."
else
	echo "usbip not available"
fi
echo

echo "== Driver bindings by interface =="
if [ -d /sys/class/net ]; then
	found_if=0
	for i in /sys/class/net/*; do
		[ -e "$i" ] || continue
		found_if=1
		n="$(basename "$i")"
		[ "$n" = "lo" ] && continue
		drv="$(readlink -f "$i/device/driver" 2>/dev/null | awk -F/ '{print $NF}')"
		printf "%s: %s\n" "$n" "${drv:-unknown}"
	done
	[ "$found_if" -eq 1 ] || echo "No network interfaces found in /sys/class/net"
else
	echo "/sys/class/net not available on this host"
fi
echo

echo "== iw dev info (channel/bw visibility) =="
if command -v iw >/dev/null 2>&1; then
	iw dev || true
else
	echo "iw not available"
fi
echo

echo "== Link state hint =="
if command -v ip >/dev/null 2>&1; then
	ip -br link 2>/dev/null || true
	echo "Note: some kernels/drivers omit channel details in 'iw dev <if> info' when interface state is DOWN."
else
	echo "ip command not available"
fi
echo

echo "== NetworkManager responsiveness hint =="
if command -v nmcli >/dev/null 2>&1; then
	nmcli general status 2>/dev/null || echo "nmcli query failed"
else
	echo "nmcli not available"
fi
if command -v systemctl >/dev/null 2>&1; then
	systemctl is-active NetworkManager 2>/dev/null || true
fi
echo

echo "== Conflict heuristic =="
has_oot=0
has_native=0
can_eval=0
if command -v lsmod >/dev/null 2>&1; then
	can_eval=1
	if lsmod | grep -q '^8814au\b'; then has_oot=1; fi
	if lsmod | grep -q '^rtw88_8814au\b'; then has_native=1; fi
else
	echo "lsmod not available; cannot evaluate loaded-module conflict"
fi

if [ "$can_eval" -eq 1 ]; then
	if [ "$has_oot" -eq 1 ] && [ "$has_native" -eq 1 ]; then
		echo "WARNING: Both out-of-tree 8814au and in-kernel rtw88_8814au are loaded."
		echo "This can cause unstable binding/behavior on RTL8814AU USB adapters."
		if [ "${awus_bound_native:-0}" -eq 1 ]; then
			echo "AWUS1900 is currently bound to in-kernel rtw88_8814au."
			echo "Operator action (non-invasive now): keep state as-is and collect evidence."
			echo "Operator action (maintenance window): rebind policy to a single driver."
		elif [ "${awus_bound_oot:-0}" -eq 1 ]; then
			echo "AWUS1900 is currently bound to out-of-tree rtl8814au."
		fi
	else
		echo "No simultaneous 8814au + rtw88_8814au load detected."
	fi
fi
