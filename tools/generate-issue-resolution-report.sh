#!/bin/sh
#
# Generate a one-by-one issue resolution report from UPSTREAM_ISSUE_TRACKING.md
# with issue-specific focus and actionable resolution steps.

set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TRACKER="$ROOT_DIR/UPSTREAM_ISSUE_TRACKING.md"
OUT="${1:-$ROOT_DIR/ISSUE_RESOLUTION_REPORT.md}"

if [ ! -f "$TRACKER" ]; then
	echo "Tracker not found: $TRACKER" >&2
	exit 1
fi

focus_for_issue() {
	case "$1" in
	159) echo "DKMS staging/build break on Kali 6.16.8" ;;
	158) echo "USB mode switch loop disconnects adapter" ;;
	157) echo "Request to increase RF power output" ;;
	156) echo "iw monitor info missing channel/bandwidth fields" ;;
	155) echo "Linux Mint connectivity stabilized via BSSID/MAC profile changes" ;;
	152) echo "Segfault/warn during driver reload disconnect path" ;;
	149) echo "AWUS1900 usability on modern distro/kernel" ;;
	148) echo "Secure Boot non-DKMS sign-install failure" ;;
	147) echo "Yocto minimal build-root failure" ;;
	145) echo "Monitor capture length mismatch (tp_snaplen/radiotap)" ;;
	141) echo "Arch/Zen runtime bind conflict and non-working state" ;;
	140) echo "DKMS build/install lifecycle inconsistencies" ;;
	133) echo "5 GHz behavior inconsistency" ;;
	129) echo "Alpine build failure in minimal environment" ;;
	122) echo "TrueNAS compile failure" ;;
	120) echo "Kernel 6.6.5 regression impacts networking stack" ;;
	117) echo "Build passes but runtime unusable" ;;
	115) echo "Throughput slowness report" ;;
	114) echo "Build failure after kernel updates" ;;
	106) echo "Arch kernel regression on specific adapter" ;;
	103) echo "Hibernate/resume instability report" ;;
	102) echo "DNS anomalies tied to USB NIC path" ;;
	99) echo "Manjaro DKMS bad return status" ;;
	96) echo "No handshake in monitor/injection workflow" ;;
	93) echo "Oracle Linux 8 compile failure" ;;
	79) echo "WPA3 capability request/issue" ;;
	76) echo "Kernel 5.19 compile error" ;;
	70) echo "RTS/CTS visibility in monitor mode" ;;
	60) echo "Kali + AWUS1900 incomplete behavior" ;;
	53) echo "Fedora Secure Boot install/runtime concerns" ;;
	47) echo "ACK capture missing in monitor mode" ;;
	23) echo "set_wiphy_netns compatibility patch request" ;;
	17) echo "Packet injection behavior on AWUS1900" ;;
	*) echo "User-specific support/build/runtime report" ;;
	esac
}

resolution_for_issue() {
	case "$1" in
	141|149|133|156)
		echo "Use hot-plug workflow: run \`tools/hot-switch-driver.sh\` (or \`tools/hotplug-issue-suite.sh\`) to A/B native vs out-of-tree binding, collect snapshots, then lock policy to one driver in maintenance window."
		;;
	120|117|115|106)
		echo "Run \`tools/runtime-issue-suite.sh\` plus \`tools/runtime-healthcheck.sh\` to capture NM/RF/USB-speed/runtime evidence; apply hot-switch policy where conflicts are observed."
		;;
	70|47)
		echo "Use updated monitor pipeline (RXFLTMAP0/1/2 + monitor CRC/ICV acceptance), then validate with monitor capture on target host and attach control-frame evidence."
		;;
	17)
		echo "Use hardened radiotap monitor TX parser and run \`tools/injection-selftest.sh --iface <if>\` on AWUS1900 host; attach generated report."
		;;
	159|140|99|114|148|147|129)
		echo "Use installer/Makefile hardening already in PR; run build-only validation and DKMS status checks. Compare logs against generated healthcheck artifacts."
		;;
	152|158|145)
		echo "Kernel-facing driver logic patched in PR. Reproduce on target hardware and confirm warning/error signatures disappear with same workload."
		;;
	155|157)
		echo "User guidance captured in README troubleshooting; validate with runtime-healthcheck evidence and connection profile settings."
		;;
	*)
		echo "Capture reproducible logs with \`tools/runtime-healthcheck.sh\`, classify as support vs code defect, and attach exact repro/environment for next patch."
		;;
	esac
}

{
	echo "# Issue Resolution Report"
	echo
	echo "- Generated: $(date -Iseconds)"
	echo "- Source tracker: \`UPSTREAM_ISSUE_TRACKING.md\`"
	echo "- Method: one-by-one issue focus + coded resolution path"
	echo
	echo "| Issue | User Report Focus | Current Status | Resolution Path |"
	echo "|---|---|---|---|"

	awk '
		/^-[ ]#([0-9]+):/ {
			line=$0
			sub(/^- /, "", line)
			num=line
			sub(/:.*/, "", num)
			sub(/^#/, "", num)

			status=line
			sub(/^#[0-9]+: /, "", status)
			title=status
			sub(/ — .*/, "", title)
			sub(/^.* — /, "", status)

			printf("%s\t%s\t%s\n", num, title, status)
		}
	' "$TRACKER" | while IFS="$(printf '\t')" read -r num title status; do
		focus="$(focus_for_issue "$num")"
		resolution="$(resolution_for_issue "$num")"
		printf '| #%s | %s | %s | %s |\n' "$num" "$focus" "$status" "$resolution"
	done
} > "$OUT"

echo "Report written: $OUT"
