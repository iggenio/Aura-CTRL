#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 iggenio
#
# Developed with the assistance of Claude (Anthropic), an AI model.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# Aura-CTRL for Asuswrt-Merlin - version 1.0.0
# Uses the Aura RGB logo of the router as a status light:
#   Lighting - how the logo looks when everything is fine (one scene, or day and night)
#   Alerts   - the logo shows problems: the colour tells the family, the animation the urgency
# Continuous effects run on the light controller (no CPU); the script only makes transitions,
# colour sequences and the animations marked High CPU (turned off by Eco mode).
# Temporary signals are never saved with "nvram commit": a reboot always clears them.
#
# Written for the BusyBox shell of the router: settings and nvram are read once per run and
# parsed with shell built-ins, so the check that cron runs every minute starts few processes.
#
# Usage: aura-ctrl.sh install | startup | check | event <action> <service> | wanevent <unit> <event>
#        | ack | test <alert> | identify <zone> [seconds] | colours [r g b] | calib <rrggbb> [r g b]
#        | effect <0-13|end> [rrggbb] | status | version | uninstall

[ -f /usr/sbin/helper.sh ] && . /usr/sbin/helper.sh

VERSION=1.0.0
TAG=aura-ctrl
ADDIR=${AURACTRL_DIR:-/jffs/addons/aura-ctrl}
SELF=$ADDIR/aura-ctrl.sh
PAGE=$ADDIR/aura-ctrl.asp
SETTINGS=${AURACTRL_SETTINGS:-/jffs/addons/custom_settings.txt}
RUN=${AURACTRL_RUN:-/tmp/aura-ctrl}
WWW=${AURACTRL_WWW:-/www/user}
STATUS=$WWW/auractrl_status.js
EVENTS=$ADDIR/events.log
KNOWN=$ADDIR/known_devices.txt
NEWDEV=$ADDIR/new_devices.txt
FPRINT=$ADDIR/fingerprint.txt
ORIG=$ADDIR/original_leds.txt
RADARSEEN=$ADDIR/radar_seen.txt
SKYSTATE=$ADDIR/skynet_update.txt
ZWDFS_RADAR=/jffs/addons/zwdfs/radar.log
ZWDFS_PHASE=/tmp/zwdfs.phase
LEASES=/var/lib/misc/dnsmasq.leases
THERMAL=${AURACTRL_THERMAL:-/sys/class/thermal/thermal_zone0/temp}
TEMP_LIMIT=90000            # millidegrees: fixed chip limit, not a user setting
USB_LIMIT=90                # percent
SKYNET_STALE=172800         # 48 hours without a successful malware feed update
I2CBUS=0
I2CADDR=0x4e

# ---------------------------------------------------------------- catalogue
# id|name|family (0-5)|severity|default duration|shown at night|default look
# look = animation:speed (0 slowest..4 fastest):direction (0 L->R, 1 R->L):colours:c1:c2:c3
ALERTS="tamper eviltwin wan prot newdev radar temp usb cac fw admin"
alert_def() {
	case "$1" in
		tamper)   D="Router tampering|0|crit|ack|1|siren:2:0:1:ff0000:ffffff:00a0ff" ;;
		eviltwin) D="Evil twin detected|0|crit|ack|1|siren:2:0:1:ff0000:ffffff:00a0ff" ;;
		wan)      D="Internet down|1|crit|active|1|siren:2:0:1:ff3000:ffffff:00a0ff" ;;
		prot)     D="Protection stalled (Skynet)|0|warn|active|0|flash:2:0:1:ff0000:ffffff:00a0ff" ;;
		newdev)   D="Unknown device|0|warn|ack|0|flash:2:0:1:ff0000:ffffff:00a0ff" ;;
		radar)    D="Radar detected (ZW-DFS)|2|warn|30|0|flash:2:0:1:a000ff:ffffff:00a0ff" ;;
		temp)     D="High temperature|3|warn|active|1|flash:2:0:1:ffc800:ffffff:00a0ff" ;;
		usb)      D="USB missing or almost full|3|warn|active|0|flash:2:0:1:ffc800:ffffff:00a0ff" ;;
		cac)      D="Radar check in progress (ZW-DFS)|2|info|active|0|pulse:2:0:1:a000ff:ffffff:00a0ff" ;;
		fw)       D="Firmware update available|4|info|active|0|breath:0:0:1:00a0ff:ffffff:00a0ff" ;;
		admin)    D="Admin session active|5|info|active|0|pulse:1:0:1:ffffff:ffffff:00a0ff" ;;
		*)        D="" ; return 1 ;;
	esac
	local IFS='|'; set -- $D
	D_NAME=$1; D_FAM=$2; D_SEV=$3; D_DUR=$4; D_NIGHT=$5; D_LOOK=$6
}
FAMILY_COLOURS="ff0000,ff3000,a000ff,ffc800,00a0ff,ffffff,00ff40,ff40c0"
DEFAULT_SCENE="static:2:0:1:0800ff:ffffff:00a0ff"

# animation id -> router effect number (E empty = made by Aura-CTRL)
router_effect() {
	case "$1" in
		off) E=0 ;; static) E=1 ;; breath) E=2 ;; flash) E=3 ;; cycle) E=4 ;; rainbow) E=5 ;; strobe) E=6 ;;
		pulse) E=7 ;; comet) E=8 ;; siren) E=9 ;; sirenmc) E=10 ;; wave) E=11 ;; yoyo) E=12 ;; starry) E=13 ;;
		*) E="" ;;
	esac
}
# animations without a colour of their own (the router chooses the colours)
no_colour() { case "$1" in off|cycle|rainbow|strobe|sirenmc|traffic) return 0 ;; esac; return 1; }
# Aura-CTRL animations: High CPU ones and their closest router effect (Eco mode, no direct control)
high_cpu() { case "$1" in fade|cbreath|alt|siren2|heart|candle|sweep) return 0 ;; esac; return 1; }
fallback() {
	case "$1" in
		fade) A=steps ;; cbreath|heart) A=breath ;; alt) A=flash ;; siren2) A=siren ;; candle) A=starry ;; sweep|multi) A=static ;; *) A=$1 ;;
	esac
}

# ---------------------------------------------------------------- helpers (built-ins only)
log() { logger -t "$TAG" "$*"; }
event_log() {
	echo "$STAMP $*" >> "$EVENTS"
	log "$*"
}
trim_events() { [ -f "$EVENTS" ] || return 0; local n=0; while read -r _; do n=$((n + 1)); done < "$EVENTS"; [ $n -gt 300 ] && { tail -200 "$EVENTS" > "$EVENTS.tmp" && mv "$EVENTS.tmp" "$EVENTS"; }; }
# time: one call to date per run (NOW epoch, HM time of day, STAMP for the logs)
clock() { set -- $(date '+%s %H%M %Y-%m-%d %H:%M:%S'); NOW=$1; HM=$2; STAMP="$3 $4"; }
uptime_s() { local u r; read -r u r < /proc/uptime; UP=${u%%.*}; }
# uptime in hundredths of a second (UPC), for the traffic rate
uptime_c() { local u r f; read -r u r < /proc/uptime; f=${u#*.}00; f=${f%${f#??}}; UPC=$(( ${u%%.*} * 100 + 1$f - 100 )); }
readf() { V=""; [ -f "$1" ] && read -r V < "$1"; }
# split "a:b:c" into $1.. without forks: split <string> <separator>; result in P1..P9
split() { local IFS="$2"; set -f; set -- $1; set +f; P1=$1 P2=$2 P3=$3 P4=$4 P5=$5 P6=$6 P7=$7 P8=$8 P9=$9; }
# rrggbb -> R G B (decimal)
rgb() { local c=$1 t; t=${c#??}; R=$((0x${c%????})); G=$((0x${t%??})); B=$((0x${c#????})); }
# decimal 0-255 -> X = 0xhh (for i2cset, as in the verified commands)
nib() { case $1 in 10) N=a ;; 11) N=b ;; 12) N=c ;; 13) N=d ;; 14) N=e ;; 15) N=f ;; *) N=$1 ;; esac; }
hex() { nib $(($1 / 16)); X="0x$N"; nib $(($1 % 16)); X="$X$N"; }

# Settings of the add-on (auractrl_* in custom_settings.txt), read once into S_* variables.
load_settings() {
	local k v
	[ -f "$SETTINGS" ] || return 0
	while read -r k v; do
		case "$k" in auractrl_*) eval "S_${k#auractrl_}=\$v" ;; esac
	done < "$SETTINGS"
}
# set V to setting $1 (without the auractrl_ prefix) or to the default $2
sv() { eval "V=\${S_$1}"; [ -z "$V" ] && V=$2; }

# nvram: "nvram get" once per variable and run (NV_* variables, dots become _). Variables that almost never
# change (model, Wi-Fi names and addresses, AiMesh nodes, WAN interface) come from a cache in $RUN that is
# rebuilt every 30 minutes. "nvram show" is not used: on some routers it can hang.
NV_STATIC="odmpid productid rc_support wl_ifnames cfg_device_list wan0_pppoe_ifname wan0_ifname"
for i in 0 1 2 3; do NV_STATIC="$NV_STATIC wl${i}_ssid wl${i}_hwaddr"; for g in 1 2 3 4; do NV_STATIC="$NV_STATIC wl$i.${g}_bss_enabled wl$i.${g}_ssid wl$i.${g}_hwaddr"; done; done
nvg() {
	local k=$1 x
	case $k in *.*) k="${k%%.*}_${k#*.}" ;; esac
	eval "x=\${NV_$k+set}"
	if [ -z "$x" ]; then V=$(nvram get "$1"); eval "NV_$k=\$V"; else eval "V=\${NV_$k}"; fi
}
load_static() {
	local f=$RUN/nv.cache k v t=0
	[ -f "$f" ] && read -r t < "$f"
	if [ $((NOW - ${t:-0})) -gt 1800 ] || [ "$1" = refresh ]; then
		[ -d "$RUN" ] || mkdir -p "$RUN"
		# key and value on two lines; a value cannot hold a newline
		{ echo "$NOW"; for k in $NV_STATIC; do v=$(nvram get "$k"); printf '%s\n%s\n' "$k" "${v%%"
"*}"; done; } > "$f.tmp" && mv "$f.tmp" "$f"
	fi
	{ read -r t; while read -r k && read -r v; do case $k in *.*) k="${k%%.*}_${k#*.}" ;; esac; eval "NV_$k=\$v"; done; } < "$f"
}

# ---------------------------------------------------------------- model
# Models whose light controller (I2C bus 0, address 0x4e) and zone map are verified:
# zones in use from left to right, and the LED colour correction measured on the logo (percent R G B).
load_model() {
	nvg odmpid; MODEL=$V; [ -z "$MODEL" ] && { nvg productid; MODEL=$V; }
	case "$MODEL" in
		GT-AXE11000) MODEL_MAP="1 2 3"; MODEL_CORR="100,60,57" ;;
		*) MODEL_MAP=""; MODEL_CORR="100,100,100" ;;
	esac
	# zones used: the verified map, or on other models the user's choice after the zone test (3 or 5)
	ZMAP=$MODEL_MAP
	if [ -z "$ZMAP" ]; then sv zones none; case $V in 3) ZMAP="1 2 3" ;; 5) ZMAP="1 2 3 4 5" ;; esac; fi
	# "command -v" is not available in every BusyBox build
	BUS=0; [ -e /dev/i2c-$I2CBUS ] && which i2cset >/dev/null 2>&1 && BUS=1
	I2C=0; [ -n "$ZMAP" ] && [ $BUS = 1 ] && I2C=1
	nvg rc_support; case " $V " in *" aura_rgb "*) AURA=1 ;; *) AURA=0 ;; esac
}
# 20-100, leading zeros removed (the page sends 3 digits; "080" would be octal in arithmetic)
pct() { local v=$1; while [ "${v#0}" != "$v" ]; do v=${v#0}; done; case $v in ''|*[!0-9]*) v=100 ;; esac; [ "$v" -ge "${2:-20}" ] && [ "$v" -le 100 ] || v=100; P=$v; }
# slider 10-100 -> power s * sqrt(s) / 10 (integer square root of s*100, one decimal)
bright_power() { local q=0; while [ $(((q + 1) * (q + 1))) -le $(($1 * 100)) ]; do q=$((q + 1)); done; P=$(($1 * q / 100)); [ $P -lt 1 ] && P=1; }
# colour correction (user's, else the model's) and brightness (day and night)
load_light() {
	sv corr "$MODEL_CORR"; split "$V" ,
	pct "$P1"; CR=$P; pct "$P2"; CG=$P; pct "$P3"; CB=$P
	sv bright "100,100"; split "$V" ,
	pct "$P1" 10; BR_DAY=$P; pct "$P2" 10; BR_NIGHT=$P
	# the eye sees LED power almost logarithmically, so the slider follows a curve: power = slider^1.5
	# (25% -> 12%, 50% -> 35%). A gentler curve than a square keeps enough colour steps for the
	# effects of the light controller (Breathing at low brightness would look jerky).
	bright_power $BR_DAY; BRP_DAY=$P; bright_power $BR_NIGHT; BRP_NIGHT=$P
	readf "$RUN/night"; if [ "$V" = 1 ]; then BR=$BRP_NIGHT; else BR=$BRP_DAY; fi
}

# ---------------------------------------------------------------- light controller (I2C)
# Only registers verified on the GT-AXE11000: zones 0x10-0x1e, effect 0x21 (01 static, 02 breathing), apply 0x2f.
# Restore at any time with: service restart_leds
w() { i2cset -y $I2CBUS $I2CADDR 0 0x80 "$1" i 2>/dev/null; i2cset -y $I2CBUS $I2CADDR 0x03 0x01 "$2" i 2>/dev/null; }
# cached write of register $1 (decimal) with value $2 (decimal): only registers that change
wc_() { local o; eval "o=\${C_$1}"; [ "$o" = "$2" ] && return 0; hex $1; local r=$X; hex $2; w $r $X; eval "C_$1=$2"; }
# Colour correction: scale each channel, bring the strongest channel back to its value (pure colours keep
# their full brightness, fades stay proportional), then apply the brightness. Sets CO_R CO_G CO_B.
corr() {
	local mi=$1 m r=$(($1 * CR)) g=$(($2 * CG)) b=$(($3 * CB))
	[ $2 -gt $mi ] && mi=$2; [ $3 -gt $mi ] && mi=$3
	m=$r; [ $g -gt $m ] && m=$g; [ $b -gt $m ] && m=$b
	if [ $m -gt 0 ]; then
		CO_R=$((r * mi / m * BR / 100)); CO_G=$((g * mi / m * BR / 100)); CO_B=$((b * mi / m * BR / 100))
	else CO_R=0; CO_G=0; CO_B=0; fi
}
zone_set() { local b=$((13 + 3 * $1)); corr $2 $3 $4; wc_ $b $CO_R; wc_ $((b + 2)) $CO_G; wc_ $((b + 1)) $CO_B; }
apply_regs() { w 0x2f 0x01; }
all_set() { local z; for z in 1 2 3 4 5; do zone_set $z $1 $2 $3; done; apply_regs; }
mcu_mode() { w 0x20 0x00; w 0x24 0x00; w 0x21 "$1"; w 0x22 0x00; w 0x23 0x00; w 0x2f 0x01; }
# static mode with all zones black, cache in sync
mcu_static_black() { local r=16; while [ $r -le 30 ]; do hex $r; w $X 0x00; eval "C_$r=0"; r=$((r + 1)); done; mcu_mode 0x01; }
all_level() { all_set $(($1 * $4 / 255)) $(($2 * $4 / 255)) $(($3 * $4 / 255)); }
# fade all zones from colour A to colour B in N steps
fade_to() { local i=0; while [ $i -le $7 ]; do all_set $(($1 + ($4 - $1) * i / $7)) $(($2 + ($5 - $2) * i / $7)) $(($3 + ($6 - $3) * i / $7)); i=$((i + 1)); done; }
# breathe colour once: up and down in 2*N steps, square brightness curve
breathe_once() { local n=$4 i=0 k; while [ $i -le $((2 * n)) ]; do k=$i; [ $k -gt $n ] && k=$((2 * n - i)); all_level $1 $2 $3 $((255 * k * k / (n * n))); i=$((i + 1)); done; }
# sleep in milliseconds: usleep, else fractional sleep, else whole seconds
msleep() {
	if [ -z "$MS_MODE" ]; then
		if which usleep >/dev/null 2>&1; then MS_MODE=u; elif sleep 0.01 2>/dev/null; then MS_MODE=f; else MS_MODE=s; fi
	fi
	case $MS_MODE in
		u) usleep $(($1 * 1000)) ;;
		f) local ms=$(($1 % 1000)); [ $ms -lt 100 ] && ms="0$ms"; [ $(($1 % 1000)) -lt 10 ] && ms="0$ms"; sleep "$(($1 / 1000)).$ms" ;;
		*) sleep $((($1 + 999) / 1000)) ;;
	esac
}
# random 0-255 without starting a process: a counter mixed with the process id
rnd() { RS=$(( (${RS:-$$} % 65537 * 75 + 74) % 65537 )); RN=$((RS % 256)); }   # small numbers: 32-bit safe

# ---------------------------------------------------------------- applying looks
# router effect through nvram: effect r g b speed (0..4) direction; nvram speed is 2 slowest .. -2 fastest
apply_router() {
	corr $2 $3 $4
	nvram set aurargb_enable=1
	nvram set aurargb_val="$CO_R,$CO_G,$CO_B,$1,$((2 - ${5:-2})),${6:-0}"
	service restart_leds >/dev/null 2>&1
}
aura_off() { nvram set aurargb_enable=0; service restart_leds >/dev/null 2>&1; }

# fade the colour shown now to black (smooth transitions, direct control only)
fade_out() {
	local z
	readf "$RUN/shown_rgb"; [ -n "$V" ] || return 0
	set -- $V; [ $# -eq 3 ] || return 0
	# 0 0 0: nothing to fade (colours chosen by the router, or the Traffic meter bars): just turn the zones off,
	# so the next router effect does not start with the previous colours
	if [ "$1$2$3" = "000" ]; then mcu_static_black; rm -f "$RUN/shown_rgb"; return 0; fi
	for z in 1 2 3 4 5; do zone_set $z $1 $2 $3; done; mcu_mode 0x01
	fade_to $1 $2 $3 0 0 0 18
	rm -f "$RUN/shown_rgb"
}
stop_worker() {
	readf "$RUN/worker.pid"; [ -n "$V" ] || return 0
	rm -f "$RUN/worker.pid"; kill "$V" 2>/dev/null || return 0
	local n=0; while [ $n -lt 10 ] && kill -0 "$V" 2>/dev/null; do msleep 100; n=$((n + 1)); done
}

# ---------------------------------------------------------------- settings
load_options() {
	sv opts "1,0,1"; split "$V" ,                  # smooth, eco, several alerts at once
	O_SMOOTH=$P1; O_ECO=$P2; O_MULTI=$P3
	sv fam "$FAMILY_COLOURS"; split "$V" ,
	FAM0=$P1 FAM1=$P2 FAM2=$P3 FAM3=$P4 FAM4=$P5 FAM5=$P6 FAM6=$P7 FAM7=$P8
}
fam_colour() { eval "V=\${FAM$1}"; }
is_night() {
	sv dn 0; [ "$V" = 1 ] || return 1
	nvg ntp_ready; [ "$V" = 1 ] || return 1
	sv times "07:00,23:00"; split "$V" ,
	local d n c
	d=$P1; d=${d%%:*}${d#*:}; n=$P2; n=${n%%:*}${n#*:}
	d=$((1$d - 10000)); n=$((1$n - 10000)); c=$((1$HM - 10000))
	if [ $d -lt $n ]; then [ $c -lt $d ] || [ $c -ge $n ]; else [ $c -ge $n ] && [ $c -lt $d ]; fi
}
# config of alert $1: AC_ON AC_DUR AC_NIGHT AC_SRC, LOOK with the colour source applied
# (setting = on:duration:night:source:animation:speed:dir:colours:c1:c2:c3)
alert_cfg() {
	alert_def "$1" || return 1
	sv "a_$1" "1:$D_DUR:$D_NIGHT:fam:$D_LOOK"
	local IFS=: col
	set -f; set -- $V; set +f
	AC_ON=$1; AC_DUR=$2; AC_NIGHT=$3; AC_SRC=$4
	case "$AC_SRC" in fam) eval "col=\${FAM$D_FAM}" ;; c1) col=$FAM6 ;; c2) col=$FAM7 ;; *) col=$9 ;; esac
	LOOK="$5:$6:$7:$8:${col:-$9}:${10}:${11}"
}
# resolve a look for this router: Eco mode and models without direct control
effective() {
	split "$1" :
	local a=$P1
	router_effect "$a"
	if [ -z "$E" ]; then
		if high_cpu "$a" && { [ "$O_ECO" = 1 ] || [ $I2C = 0 ]; }; then fallback "$a"; a=$A
		elif [ "$a" = multi ] && [ $I2C = 0 ]; then a=static
		fi
	fi
	EFF="$a:${1#*:}"
}

# ---------------------------------------------------------------- alert detection
# Booting (from services-start until the clock is set and the router is up 60 s): internet, USB,
# Skynet and tampering are not checked, because other services and add-ons are still starting.
booting() { [ -f "$RUN/booting" ]; }

# tampering: not checked in the first 10 minutes (other add-ons are still adding their cron jobs)
# the fingerprint reads about 30 nvram variables: recomputed every 5 minutes, the last result kept in between
det_tamper() {
	[ -f "$FPRINT" ] || return 1
	booting && return 1
	[ $UP -lt 600 ] && return 1
	if [ $((1$HM % 5)) = 0 ] || [ ! -f "$RUN/tamper.last" ]; then
		fingerprint; readf "$FPRINT"
		if [ "$FP" != "$V" ]; then echo 1 > "$RUN/tamper.last"; else echo 0 > "$RUN/tamper.last"; fi
	fi
	readf "$RUN/tamper.last"; [ "$V" = 1 ]
}
fingerprint() {
	local v s=""
	for v in wan_dnsenable_x wan_dns1_x wan_dns2_x wan0_dnsenable_x wan0_dns1_x wan0_dns2_x \
		dhcp_dns1_x dhcp_dns2_x dhcpd_dns_router dnspriv_enable dnspriv_rulelist \
		misc_http_x misc_httpport_x misc_httpsport_x http_enable sshd_enable sshd_port sshd_pass sshd_authkeys \
		vts_enable_x vts_rulelist dmz_ip upnp_enable fw_enable_x http_username http_passwd \
		vpn_server_unit vpn_serverx_start wgs_enable; do
		nvg $v; s="$s$v=$V
"
	done
	FP=$( { printf '%s' "$s"; md5sum /jffs/scripts/* 2>/dev/null; cru l 2>/dev/null | sort; } | md5sum)
	FP=${FP%% *}
}

det_eviltwin() {
	local i g ifn ours="" ssids=""
	for i in 0 1 2 3; do
		nvg wl${i}_ssid; [ -n "$V" ] && ssids="$ssids$V
"
		nvg wl${i}_hwaddr; [ -n "$V" ] && ours="$ours $V"
		for g in 1 2 3 4; do
			nvg wl$i.${g}_bss_enabled; [ "$V" = 1 ] || continue
			nvg wl$i.${g}_ssid; [ -n "$V" ] && ssids="$ssids$V
"
			nvg wl$i.${g}_hwaddr; [ -n "$V" ] && ours="$ours $V"
		done
	done
	[ -n "$ssids" ] || return 1
	nvg cfg_device_list; ours="$ours $V"    # AiMesh nodes (MACs inside the list)
	printf '%s' "$ssids" > "$RUN/ssids"
	nvg wl_ifnames
	for ifn in $V; do wl -i "$ifn" scanresults 2>/dev/null; done | awk -v ours="$ours" -v sf="$RUN/ssids" '
		function hx(s,   i, v) { v = 0; s = toupper(s); for (i = 1; i <= length(s); i++) v = v * 16 + index("0123456789ABCDEF", substr(s, i, 1)) - 1; return v }
		function tail3(m) { return hx(substr(m, 10, 2) substr(m, 13, 2) substr(m, 16, 2)) }
		# a BSSID is ours if it is a known radio or AiMesh node MAC, or differs from one only in
		# the last 3 bytes by 16 or less (virtual interfaces of the same device)
		function own(m,   i, x, d) {
			m = toupper(m)
			for (i = 1; i <= nm; i++) {
				x = mac[i]; if (x == m) return 1
				if (substr(x, 4, 5) == substr(m, 4, 5)) { d = tail3(x) - tail3(m); if (d < 0) d = -d; if (d <= 16) return 1 }
			}
			return 0
		}
		BEGIN {
			while ((getline l < sf) > 0) if (l != "") want[l] = 1
			n = split(toupper(ours), a, /[^0-9A-F:]+/)
			for (i = 1; i <= n; i++) if (a[i] ~ /^([0-9A-F][0-9A-F]:){5}[0-9A-F][0-9A-F]$/) mac[++nm] = a[i]
		}
		/^SSID: / { ss = $0; sub(/^SSID: "/, "", ss); sub(/"[ \t]*$/, "", ss); next }
		/^BSSID: / { if ((ss in want) && !own($2)) print toupper($2); ss = "" }
	' | sort -u > "$RUN/eviltwin.now"
	[ -s "$RUN/eviltwin.now" ] || return 1
	cat "$RUN/eviltwin.now" "$RUN/eviltwin.list" 2>/dev/null | sort -u > "$RUN/eviltwin.l2"; mv "$RUN/eviltwin.l2" "$RUN/eviltwin.list"
	return 0
}
det_wan() {
	booting && return 1
	nvg wan_primary; local p=${V:-0}
	nvg wan${p}_enable; [ "$V" = 0 ] && return 1
	nvg wan${p}_state_t; [ "$V" != 2 ]
}
det_prot() {
	[ -f /jffs/scripts/firewall ] || return 1
	local l loc="" c=0 old t
	while read -r l; do case "$l" in *skynetloc=*) loc=${l#*skynetloc=}; loc=${loc%% *}; break ;; esac; done < /jffs/scripts/firewall
	[ -n "$loc" ] || return 1
	booting && return 1
	[ $UP -lt 600 ] && return 1
	ipset -L -n 2>/dev/null | grep -qx Skynet-Master || return 0
	[ -f "$loc/events.log" ] || return 1
	c=$(grep -aic 'update malware sources' "$loc/events.log")
	readf "$SKYSTATE"; set -- $V; old=$1; t=$2
	if [ -z "$old" ] || [ "$c" != "$old" ]; then echo "$c $NOW" > "$SKYSTATE"; return 1; fi
	[ $((NOW - t)) -gt $SKYNET_STALE ]
}
det_newdev() {
	[ -f "$LEASES" ] || return 1
	if [ ! -f "$KNOWN" ]; then awk '{print tolower($2)}' "$LEASES" | sort -u > "$KNOWN"; return 1; fi
	# MACs in the leases that are neither known nor already reported
	[ -f "$NEWDEV" ] || : > "$NEWDEV"
	awk -v L="$LEASES" 'FILENAME != L { seen[tolower($1)] = 1; next } { m = tolower($2) } !(m in seen) { print m, $4; seen[m] = 1 }' \
		"$KNOWN" "$NEWDEV" "$LEASES" > "$RUN/newdev.now"
	if [ -s "$RUN/newdev.now" ]; then
		local m n
		while read -r m n; do echo "$m $n" >> "$NEWDEV"; event_log "unknown device $m ($n) got an address"; done < "$RUN/newdev.now"
	fi
	[ -s "$NEWDEV" ]
}
# true once for each new line in the ZW-DFS radar log
det_radar() {
	[ -f "$ZWDFS_RADAR" ] || return 1
	local c=0 s
	while read -r _; do c=$((c + 1)); done < "$ZWDFS_RADAR"
	readf "$RADARSEEN"; s=$V
	[ "$c" = "$s" ] || echo "$c" > "$RADARSEEN"
	[ -n "$s" ] && [ "$c" -gt "$s" ]
}
det_cac() { readf "$ZWDFS_PHASE"; case "$V" in Scanning*|Moving*) return 0 ;; esac; return 1; }
det_temp() { readf "$THERMAL"; [ -n "$V" ] && [ "$V" -gt $TEMP_LIMIT ]; }
det_usb() {
	booting && return 1
	[ -f "$RUN/usb.base" ] || grep '^/dev/sd' /proc/mounts | awk '{print $1, $2}' > "$RUN/usb.base"
	[ -s "$RUN/usb.base" ] || return 1
	df -k 2>/dev/null | awk -v l=$USB_LIMIT -v base="$RUN/usb.base" '
		BEGIN { while ((getline x < base) > 0) want[x] = 1 }
		$1 ~ /^\/dev\/sd/ { delete want[$1 " " $NF]; p = $5; sub(/%/, "", p); if (p + 0 > l) f = 1 }
		END { for (k in want) f = 1; exit !f }'
}
det_fw() { nvg webs_state_flag; [ -n "$V" ] && [ "$V" != 0 ] && { nvg webs_state_error; [ "$V" = 0 ]; }; }
det_admin() {
	nvg sshd_port; local port=${V:-22} lt to
	netstat -tn 2>/dev/null | awk -v p=":$port" '$6 == "ESTABLISHED" && substr($4, length($4) - length(p) + 1) == p { f = 1 } END { exit !f }' && return 0
	nvg login_timestamp; lt=$V; [ -n "$lt" ] || return 1
	nvg http_autologout; to=$V; [ -z "$to" ] || [ "$to" = 0 ] && to=15
	[ "$lt" -gt 0 ] 2>/dev/null && [ $((UP - lt)) -ge 0 ] && [ $((UP - lt)) -lt $((to * 60)) ]
}

# State of one alert in $RUN/a: <id>.c condition true last run, <id>.t time of the last rising edge
# (cleared by Acknowledge), <id>.k acknowledged while the condition stays true, <id>.on shown.
update_alert() {
	local f=$RUN/a/$1 c=$2 dur=$3
	if [ "$c" = 1 ]; then
		[ -f "$f.c" ] || { echo "$NOW" > "$f.t"; rm -f "$f.k"; : > "$f.c"; }
	else
		[ -f "$f.c" ] && rm -f "$f.c" "$f.k"
		[ "$dur" = active ] && [ -f "$f.t" ] && rm -f "$f.t"
	fi
	case "$dur" in
		active) [ -f "$f.c" ] && [ ! -f "$f.k" ] ;;
		ack) [ -f "$f.t" ] ;;
		*) [ -f "$f.t" ] || return 1; readf "$f.t"; [ $((NOW - V)) -lt $((dur * 60)) ] ;;
	esac
}

# ---------------------------------------------------------------- deciding what to show
# ACTIVE: "rank|family|index|id" lines, most important first
evaluate() {
	[ -d "$RUN/a" ] || mkdir -p "$RUN/a"
	NIGHT=0; is_night && NIGHT=1
	[ "$NIGHT" = 1 ] && BR=$BRP_NIGHT || BR=$BRP_DAY
	sv alerts 1; local alerts_on=$V i=0 id r list="" was f
	for id in $ALERTS; do
		i=$((i + 1))
		alert_cfg $id; f=$RUN/a/$id
		if [ "$alerts_on" != 1 ] || [ "$AC_ON" != 1 ]; then
			[ -f "$f.on" ] || [ -f "$f.t" ] || [ -f "$f.c" ] && rm -f "$f".*
			continue
		fi
		local c=0; det_$id && c=1
		was=0; [ -f "$f.on" ] && was=1
		if update_alert $id $c "$AC_DUR"; then
			[ $was = 0 ] && { : > "$f.on"; event_log "alert on: $D_NAME"; }
			[ $NIGHT = 1 ] && [ "$AC_NIGHT" != 1 ] && continue
			case "$D_SEV" in crit) r=0 ;; warn) r=1 ;; *) r=2 ;; esac
			list="$list$((r * 1000 + D_FAM * 100 + i)) $id
"
		else
			[ $was = 1 ] && { rm -f "$f.on"; event_log "alert off: $D_NAME"; }
		fi
	done
	# sort by severity, family, catalogue order (the key is 4 digits)
	ACTIVE=""; [ -n "$list" ] && ACTIVE=$(printf '%s' "$list" | sort -n | while read -r k id; do printf '%s ' "$id"; done)
	ACTIVE=${ACTIVE% }
	echo "$NIGHT" > "$RUN/night"
	echo "$ACTIVE" > "$RUN/active"
}

# PLAN = one line describing exactly what the logo must show; applied only when it changes
make_plan() {
	sv aura 1; [ "$V" = 1 ] || { PLAN=auraoff; return; }
	local top toprank others l id
	if [ -f "$RUN/test" ]; then
		readf "$RUN/test"; set -- $V
		if [ "${2:-0}" -gt "$NOW" ]; then alert_cfg "$1"; effective "$LOOK"; PLAN="show $EFF test:$1 br:100"; return; fi
		rm -f "$RUN/test"
	fi
	if [ -z "$ACTIVE" ]; then
		if [ "$NIGHT" = 1 ]; then sv night "$DEFAULT_SCENE"; else sv day "$DEFAULT_SCENE"; fi
		local w=day; [ "$NIGHT" = 1 ] && w=night
		effective "$V"; PLAN="show $EFF scene:$w br:$BR"; return
	fi
	set -- $ACTIVE; top=$1; shift
	alert_cfg $top; toprank=$D_SEV; effective "$LOOK"; local look=$EFF
	if [ $# -gt 0 ] && [ "$O_MULTI" = 1 ]; then
		others=""
		for id in "$@"; do
			alert_cfg $id; split "$LOOK" :
			no_colour "$P1" && continue
			others="$others,$P5"
		done
		if [ -n "$others" ]; then
			# alerts share the logo only with a known zone map, and never when a Critical alert is shown
			if [ $I2C = 1 ] && [ "$toprank" != crit ]; then
				split "$look" :; local base=$P1 cols="$P5$others"
				split "$cols" ,; cols=$P1${P2:+,$P2}${P3:+,$P3}
				l="$top"; [ -n "$1" ] && l="$l,$1"; [ -n "$2" ] && l="$l,$2"
				PLAN="share $cols $base alerts:$l br:$BR"; return
			fi
			PLAN="show $look alert:$top remind:${others#,} br:$BR"; return
		fi
	fi
	PLAN="show $look alert:$top br:$BR"
}

# ---------------------------------------------------------------- output
apply_plan() {
	local p=$1 kind look remind="" a e
	stop_worker
	if [ "$p" = auraoff ]; then aura_off; rm -f "$RUN/shown_rgb"; return; fi
	[ $I2C = 1 ] && [ "$O_SMOOTH" = 1 ] && fade_out
	set -- $p; kind=$1; look=$2
	case " $p " in *" remind:"*) remind=${p#* remind:}; remind=${remind%% *} ;; esac
	case "$kind" in
		show)
			split "$look" :; a=$P1; local sp=$P2 dr=$P3
			rgb "${P5:-000000}"
			router_effect "$a"; e=$E
			if [ -n "$e" ]; then
				[ "$e" = 0 ] && { R=0; G=0; B=0; }
				apply_router $e $R $G $B "$sp" "$dr"
				if no_colour "$a"; then echo "0 0 0" > "$RUN/shown_rgb"; else echo "$R $G $B" > "$RUN/shown_rgb"; fi
				[ -n "$remind" ] && start_worker "$look" "$remind"
			elif [ "$a" = multi ]; then
				nvram set aurargb_enable=1
				mcu_static_black; spread_colours "$look" 0; apply_regs
				echo "$R $G $B" > "$RUN/shown_rgb"
				[ -n "$remind" ] && start_worker "$look" "$remind"
			else
				nvram set aurargb_enable=1
				if [ "$a" = traffic ]; then echo "0 0 0" > "$RUN/shown_rgb"; else echo "$R $G $B" > "$RUN/shown_rgb"; fi
				start_worker "$look" "$remind"
			fi ;;
		share)
			nvram set aurargb_enable=1
			local cols=$2 z k n c first=""
			router_effect "$3"; local base=$E
			mcu_static_black
			set -- $ZMAP; n=$#
			# most severe alert on the rightmost zone in use, the next ones to its left;
			# zones not in the map and zones left over take the colour of the most severe / last alert
			k=$n
			split "$cols" ,; local c1=$P1 c2=$P2 c3=$P3
			for c in $c1 $c2 $c3; do
				[ -z "$first" ] && { first=$c; rgb $c; for z in 1 2 3 4 5; do zone_set $z $R $G $B; done; }
				eval "z=\${$k}"; rgb $c; zone_set $z $R $G $B
				k=$((k - 1)); [ $k -lt 1 ] && break
			done
			while [ $k -ge 1 ]; do eval "z=\${$k}"; zone_set $z $R $G $B; k=$((k - 1)); done
			# common effect: the light controller breathing (verified) unless the top alert is Static
			if [ "$base" = 1 ]; then mcu_mode 0x01; else mcu_mode 0x02; fi
			rgb $first; echo "$R $G $B" > "$RUN/shown_rgb" ;;
	esac
}

# colours of a look spread across the 5 zones: zone k gets colour min(k, n); offset rotates them (Sweep)
spread_colours() {
	local z k n c1 c2 c3
	split "$1" :; n=${P4:-1}; [ "$n" -ge 1 ] 2>/dev/null || n=1; c1=$P5 c2=$P6 c3=$P7
	for z in 1 2 3 4 5; do
		k=$(( (z - 1 + $2) % 5 )); [ $k -ge $n ] && k=$((n - 1))
		case $k in 0) rgb $c1 ;; 1) rgb $c2 ;; *) rgb $c3 ;; esac
		zone_set $z $R $G $B
	done
}
# Two-colour siren: zones in odd places of the zone map (1st, 3rd, 5th) form set A, the others set B;
# zones outside the map join a set by their own number, so all 5 zones are always written.
siren_sets() {
	local z k p q
	SG_A=""; SG_B=""
	for z in 1 2 3 4 5; do
		p=$z; k=0; for q in $ZMAP; do k=$((k + 1)); [ "$q" = "$z" ] && p=$k; done
		if [ $((p % 2)) = 1 ]; then SG_A="$SG_A $z"; else SG_B="$SG_B $z"; fi
	done
}
# 3 fast flashes of colour r g b on the zones $1 (the other zones stay off); $5 = speed factor x100
siren_side() {
	local z k=0 t=$((45 * $5 / 100))
	while [ $k -lt 3 ]; do
		for z in $1; do zone_set $z $2 $3 $4; done; apply_regs; msleep $t
		for z in $1; do zone_set $z 0 0 0; done; apply_regs; msleep $t
		k=$((k + 1))
	done
}
start_worker() { "$SELF" worker "$1" "$2" >/dev/null 2>&1 & echo $! > "$RUN/worker.pid"; }

# ---------------------------------------------------------------- background worker
# Runs Aura-CTRL animations and the 10-second reminders of the other active alerts.
worker() {
	local look=$1 remind=$2 a sp dr n f hold idx=0 nxt off=0 last r g b r2 g2 b2 c k e
	split "$look" :; a=$P1; sp=${P2:-2}; dr=${P3:-0}; n=${P4:-1}; [ "$n" -ge 1 ] 2>/dev/null || n=1
	local C1=$P5 C2=${P6:-$P5} C3=${P7:-$P5}
	# speed factor x100: slowest 200 .. fastest 50; hold time of Colour steps
	case $sp in 0) f=200; hold=30 ;; 1) f=150; hold=10 ;; 3) f=75; hold=3 ;; 4) f=50; hold=2 ;; *) f=100; hold=5 ;; esac
	router_effect "$a"; e=$E
	[ $I2C = 1 ] && [ -z "$e" ] && [ "$a" != multi ] && mcu_static_black
	[ "$a" = siren2 ] && siren_sets
	uptime_s; last=$UP
	while :; do
		case $idx in 0) rgb $C1 ;; 1) rgb $C2 ;; *) rgb $C3 ;; esac; r=$R g=$G b=$B
		nxt=$(( (idx + 1) % n ))
		case $nxt in 0) rgb $C1 ;; 1) rgb $C2 ;; *) rgb $C3 ;; esac; r2=$R g2=$G b2=$B
		case "$a" in
			steps)
				if [ $I2C = 1 ]; then
					if [ "$O_SMOOTH" = 1 ]; then fade_to 0 0 0 $r $g $b 9; else all_set $r $g $b; fi
					sleep $hold
					[ "$O_SMOOTH" = 1 ] && fade_to $r $g $b 0 0 0 9
				else
					apply_router 1 $r $g $b 2 0; sleep $hold
				fi
				idx=$nxt ;;
			traffic) traffic_step; sv trate 5; case $V in 3|5|10) sleep $V ;; *) sleep 5 ;; esac ;;
			fade) fade_to $r $g $b $r2 $g2 $b2 $((54 * f / 100)); idx=$nxt ;;
			cbreath) breathe_once $r $g $b $((27 * f / 100)); idx=$nxt ;;
			alt) all_set $r $g $b; msleep $((500 * f / 100)); idx=$nxt ;;
			siren2)
				# emergency vehicle: the two sets of zones flash fast in turn, set A in colour 1, set B in colour 2
				siren_side "$SG_A" $(rgb $C1; echo $R $G $B) $f
				siren_side "$SG_B" $(rgb $C2; echo $R $G $B) $f ;;
			heart)
				breathe_once $r $g $b 3; breathe_once $r $g $b 3
				all_set 0 0 0; msleep $((700 * f / 100)) ;;
			candle) rnd; all_level $r $g $b $((150 + RN * 105 / 255)); rnd; msleep $((60 + RN * f / 100)) ;;
			sweep)
				spread_colours "$look" $off; apply_regs; msleep $((600 * f / 100))
				if [ "$dr" = 1 ]; then off=$(( (off + 4) % 5 )); else off=$(( (off + 1) % 5 )); fi ;;
			*) sleep 2 ;;   # router effect or Multi-colour: only reminders
		esac
		uptime_s
		if [ -n "$remind" ] && [ $((UP - last)) -ge 10 ]; then
			split "$remind" ,
			for c in $P1 $P2 $P3 $P4 $P5; do
				rgb $c
				if [ $I2C = 1 ]; then mcu_static_black; all_set $R $G $B; msleep 800; all_set 0 0 0; msleep 200
				else apply_router 1 $R $G $B 2 0; sleep 1; fi
			done
			# back to the main animation
			rgb $C1
			if [ -n "$e" ]; then apply_router $e $R $G $B "$sp" "$dr"
			elif [ "$a" = multi ]; then mcu_static_black; spread_colours "$look" 0; apply_regs
			elif [ $I2C = 1 ]; then mcu_static_black; fi
			uptime_s; last=$UP
		fi
	done
}

# Traffic meter. 100% = the speed of the internet line entered by the user (auractrl_traffic =
# <download Mbps>,<upload Mbps>); download and upload are measured separately and the busier sets the meter.
# Without the speeds the meter stays at rest. Measured every 3, 5 or 10 seconds (auractrl_trate, default 5). Colours: the 3 colours of the look (default green, yellow, red).
# With direct control (known zone map): a bar meter, every zone always on; each zone covers an equal part of
# the traffic and goes from 20% to 100% of its power across it (then the brightness applies). With 5 zones
# the colours in between are mixed. Without direct control: one colour, colour 1 -> 2 -> 3 as traffic grows.
traffic_step() {
	local ifn rx tx dt dr dtx p pu down up
	nvg wan0_pppoe_ifname; ifn=$V; [ -n "$ifn" ] && [ -d /sys/class/net/$ifn ] || { nvg wan0_ifname; ifn=$V; }
	[ -d "/sys/class/net/$ifn" ] || return 0
	# The counters exceed 32 bits (the router shell may compute with 32 bits only): awk reads them and
	# passes KiB modulo 10^9, small numbers for the shell. One short process per interval.
	set -- $(awk -v d=/sys/class/net/$ifn/statistics 'BEGIN { getline r < (d "/rx_bytes"); getline t < (d "/tx_bytes"); printf "%d %d", (r / 1024) % 1000000000, (t / 1024) % 1000000000 }')
	rx=$1; tx=$2
	uptime_c
	sv traffic ""; split "$V" ,
	if [ "$P1" = manual ]; then down=$P2; up=$P3; else down=$P1; up=$P2; fi   # older format "manual,d,u" also accepted
	[ "$down" -gt 0 ] 2>/dev/null && [ "$up" -gt 0 ] 2>/dev/null || { down=""; up=""; }
	# first call: the meter at rest at once (the first measure needs one interval)
	if [ -z "$T_LAST" ]; then traffic_draw 0 0; T_P=0; echo "${down:+0}" > "$RUN/traffic"; fi
	if [ -n "$T_LAST" ] && [ -n "$down" ]; then
		# KiB/s = KiB * 100 / hundredths of a second; percent of the line speed in Mbps:
		# KiB/s * 8.192 / Mbps -> KiB/s * 82 / (Mbps * 100). All numbers stay well below 2^31.
		dt=$((UPC - T_LAST)); [ $dt -lt 1 ] && dt=1
		dr=$((rx - T_RX)); dtx=$((tx - T_TX))
		[ $dr -lt 0 ] && dr=$((dr + 1000000000)); [ $dtx -lt 0 ] && dtx=$((dtx + 1000000000))
		dr=$((dr * 100 / dt)); dtx=$((dtx * 100 / dt))
		p=$((dr * 82 / (down * 100))); pu=$((dtx * 82 / (up * 100))); [ $pu -gt $p ] && p=$pu
		[ $p -gt 100 ] && p=100
		p=$((p / 5 * 5))   # 5% steps: fewer writes
		if [ "$p" != "$T_P" ]; then traffic_draw ${T_P:-0} $p; echo "$p" > "$RUN/traffic"; T_P=$p; fi
	fi
	T_LAST=$UPC; T_RX=$rx; T_TX=$tx
}
# colours of the meter from the look (TC1..TC3), defaults when the look has none
traffic_colours() {
	if [ "${n:-0}" -ge 3 ] 2>/dev/null; then TC1=$C1 TC2=$C2 TC3=$C3; else TC1=00ff00 TC2=ffc800 TC3=ff0000; fi
}
# mix of two rrggbb colours at w/100 of the way -> R G B
mix() { rgb $1; local r=$R g=$G b=$B; rgb $2; R=$((r + (R - r) * $3 / 100)); G=$((g + (G - g) * $3 / 100)); B=$((b + (B - b) * $3 / 100)); }
# power of zone i (0-based) of n for traffic p: 20-100% across its part (LV)
bar_level() { local lo=$(($1 * 100 / $2)) hi=$((($1 + 1) * 100 / $2)) l; if [ $3 -le $lo ]; then l=20; elif [ $3 -ge $hi ]; then l=100; else l=$((20 + 80 * ($3 - lo) / (hi - lo))); fi; LV=$l; }
# colour of zone i of n: 3 zones = the 3 colours; 5 zones = colour 1, mix, colour 2, mix, colour 3
bar_colour() {
	if [ $2 -le 3 ]; then case $1 in 0) rgb $TC1 ;; 1) rgb $TC2 ;; *) rgb $TC3 ;; esac
	else case $1 in 0) rgb $TC1 ;; 1) mix $TC1 $TC2 50 ;; 2) rgb $TC2 ;; 3) mix $TC2 $TC3 50 ;; *) rgb $TC3 ;; esac; fi
}
# draw the meter, fading in 4 steps from traffic $1 to traffic $2; zones outside the map stay off
traffic_draw() {
	traffic_colours
	if [ $I2C != 1 ]; then
		if [ $2 -le 50 ]; then mix $TC1 $TC2 $(($2 * 2)); else mix $TC2 $TC3 $((($2 - 50) * 2)); fi
		apply_router 1 $R $G $B 2 0; return
	fi
	local nz z i s=1 p
	set -- $1 $2 $ZMAP; local from=$1 to=$2; shift 2; nz=$#
	[ "$T_DRAWN" = 1 ] || { mcu_static_black; T_DRAWN=1; s=4; from=$to; }
	while [ $s -le 4 ]; do
		p=$((from + (to - from) * s / 4)); i=0
		for z in "$@"; do bar_colour $i $nz; bar_level $i $nz $p; zone_set $z $((R * LV / 100)) $((G * LV / 100)) $((B * LV / 100)); i=$((i + 1)); done
		apply_regs; s=$((s + 1)); [ $s -le 4 ] && msleep 120
	done
}

# ---------------------------------------------------------------- main actions
lock() {
	local n=0
	while ! mkdir "$RUN/lock" 2>/dev/null; do
		n=$((n + 1)); [ $n -ge 30 ] && { rm -rf "$RUN/lock"; continue; }
		sleep 1
	done
	trap 'rmdir "$RUN/lock" 2>/dev/null' EXIT
}
unlock() { rmdir "$RUN/lock" 2>/dev/null; trap - EXIT; }

do_check() {
	[ -d "$RUN" ] || mkdir -p "$RUN"
	# a test is running; an effect test left on is ended after 10 minutes
	if [ -f "$RUN/calib" ]; then
		readf "$RUN/calib"; set -- $V
		if [ "$1" = effect ] && [ $((NOW - ${2:-0})) -gt 600 ]; then rm -f "$RUN/calib"; else write_status; return 0; fi
	fi
	[ -f "$RUN/identify" ] && { write_status; return 0; }
	nvg led_disable
	if [ $AURA = 1 ] && [ "$V" != 1 ]; then     # router LEDs turned off: leave the logo alone
		lock
		evaluate
		make_plan
		readf "$RUN/plan"
		if [ "$PLAN" != "$V" ] || [ "$1" = force ]; then
			apply_plan "$PLAN"
			echo "$PLAN" > "$RUN/plan"
		fi
		unlock
	fi
	write_status
}

do_ack() {
	[ -d "$RUN/a" ] || mkdir -p "$RUN/a"
	local id f
	for id in $ALERTS; do f=$RUN/a/$id; rm -f "$f.t"; [ -f "$f.c" ] && : > "$f.k"; done
	fingerprint; echo "$FP" > "$FPRINT"; echo 0 > "$RUN/tamper.last"
	if [ -s "$NEWDEV" ]; then awk '{print $1}' "$NEWDEV" "$KNOWN" | sort -u > "$KNOWN.tmp" && mv "$KNOWN.tmp" "$KNOWN"; : > "$NEWDEV"; fi
	rm -f "$RUN/eviltwin.list"
	event_log "alerts acknowledged"
	do_check
}

do_test() {
	alert_def "$1" || { echo "unknown alert: $1"; return 1; }
	[ -d "$RUN" ] || mkdir -p "$RUN"
	echo "$1 $((NOW + 10))" > "$RUN/test"
	do_check
	(sleep 11; "$SELF" check) >/dev/null 2>&1 &
}

# Tests at full brightness, while the periodic check leaves the logo alone. At the end the logo is
# restored with restart_leds (or the scene) and the add-on applies its plan again.
test_begin() {
	[ -d "$RUN" ] || mkdir -p "$RUN"
	{ [ -f "$RUN/calib" ] || [ -f "$RUN/identify" ]; } && return 1
	echo "$2" > "$RUN/$1"
	stop_worker; rm -f "$RUN/plan" "$RUN/shown_rgb"
	BR=100; write_status
	return 0
}
test_end() { rm -f "$RUN/$1"; load_light; do_check force; }

# Diagnostics: one zone in white, the others off, for 3-10 seconds (registers verified on the GT-AXE11000).
do_identify() {
	local z=$1 s=${2:-5}
	[ "$z" -ge 1 ] 2>/dev/null && [ "$z" -le 5 ] || { echo "zone must be 1 to 5"; return 1; }
	[ "$s" -ge 3 ] 2>/dev/null && [ "$s" -le 10 ] || s=5
	[ $BUS = 1 ] || { log "zone test: no I2C bus on this router"; return 1; }
	test_begin identify $z || return 0
	nvram set aurargb_enable=1
	log "zone test: zone $z in white for $s s"
	mcu_static_black; CR=100 CG=100 CB=100; zone_set $z 255 255 255; apply_regs
	sleep $s
	service restart_leds >/dev/null 2>&1
	test_end identify
}
# Colour correction: one colour (rrggbb) for 5 seconds; optional r g b percentages to try before saving
do_calib() {
	case "$1" in [0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) ;; *) echo "colour must be rrggbb"; return 1 ;; esac
	[ -n "$2" ] && { pct "$2"; CR=$P; pct "$3"; CG=$P; pct "$4"; CB=$P; }
	test_begin calib $1 || return 0
	rgb $1; apply_router 1 $R $G $B 2 0
	log "colour test: $R,$G,$B shown as $CO_R,$CO_G,$CO_B (correction $CR,$CG,$CB)"
	sleep 5
	test_end calib
}
# the family colours one after the other, 4 s each
do_colours() {
	[ -n "$1" ] && { pct "$1"; CR=$P; pct "$2"; CG=$P; pct "$3"; CB=$P; }
	test_begin calib families || return 0
	local i=0 c
	for n in Security Connectivity Wi-Fi System Maintenance Activity "Custom 1" "Custom 2"; do
		fam_colour $i; c=$V; echo "$c" > "$RUN/calib"; write_status
		rgb $c; apply_router 1 $R $G $B 2 0
		echo "$n: #$c -> on the logo $CO_R,$CO_G,$CO_B"
		sleep 4; i=$((i + 1))
	done
	test_end calib
}
# One router effect (0-13) on the logo until "effect end", to compare it with the page preview.
# The periodic check leaves the logo alone meanwhile, for at most 10 minutes.
EFFECT_NAMES="Off Static Breathing Flash Color_Cycle Rainbow Strobing Pulse Comet Siren Siren_multicolor Wave Glowing_Yoyo Starry_Night"
do_effect() {
	if [ "$1" = end ]; then
		[ -f "$RUN/calib" ] || return 0
		readf "$RUN/calib"; case "$V" in effect*) test_end calib; echo "back to the scene" ;; esac
		return 0
	fi
	[ "$1" -ge 0 ] 2>/dev/null && [ "$1" -le 13 ] || { echo "effect must be 0 to 13, or end"; return 1; }
	local c=${2:-ff0000} n
	readf "$RUN/calib"; case "$V" in effect*) rm -f "$RUN/calib" ;; esac
	test_begin calib "effect $NOW" || { echo "another test is running"; return 1; }
	set -- $1 $EFFECT_NAMES; n=$1; shift $((n + 1)); n="$n ${1:-?}"
	rgb $c; apply_router ${n%% *} $R $G $B 2 0
	echo "effect ${n%% *}: $(echo "${n#* }" | tr _ ' ') - when done: $0 effect end"
}

# ---------------------------------------------------------------- status for the page
# auractrl_status.js: the fields go to awk in one environment variable (separated by \037), and awk
# writes them JSON-safe (backslash, quotes, control characters)
write_status() {
	[ -d "$WWW" ] || mkdir -p "$WWW"
	local u plan ident calib traffic temp nd="" et="" ev="" act="" id
	u=$(printf '\037')
	readf "$RUN/plan"; plan=$V; readf "$RUN/identify"; ident=$V; readf "$RUN/calib"; calib=$V
	readf "$RUN/traffic"; traffic=$V; readf "$THERMAL"; temp=$V
	[ -n "$ACTIVE" ] || { readf "$RUN/active"; ACTIVE=$V; }
	for id in $ACTIVE; do act="$act${act:+,}$id"; done
	[ -s "$NEWDEV" ] && nd=$(tr '\n' ';' < "$NEWDEV")
	[ -s "$RUN/eviltwin.list" ] && et=$(tr '\n' ' ' < "$RUN/eviltwin.list")
	[ -f "$EVENTS" ] && ev=$(tail -15 "$EVENTS" | tr '\n' '|')
	nvg led_disable
	AC_KV="version$u$VERSION${u}time$u$STAMP${u}model$u$MODEL${u}supported$u$AURA${u}i2c$u$I2C${u}zones$u$ZMAP${u}model_zones$u$MODEL_MAP${u}bus$u$BUS${u}leds_off$u$V${u}night$u$NIGHT${u}active$u$act${u}plan$u$plan${u}identify$u$ident${u}calib$u$calib${u}corr$u$CR,$CG,$CB${u}corr_model$u$MODEL_CORR${u}bright$u$BR_DAY,$BR_NIGHT${u}traffic$u$traffic${u}newdev$u$nd${u}eviltwin$u$et${u}temp$u$temp${u}events$u$ev"
	AC_KV="$AC_KV" awk -v sep="$u" 'BEGIN {
		n = split(ENVIRON["AC_KV"], kv, sep); printf "var auractrl_status = {"
		for (i = 1; i < n; i += 2) { v = kv[i + 1]; gsub(/\\/, "\\\\", v); gsub(/"/, "\\\"", v); gsub(/[\001-\037]/, " ", v); printf "%s\"%s\":\"%s\"", (i > 1 ? "," : ""), kv[i], v }
		print "};" }' > "$STATUS.tmp" && mv "$STATUS.tmp" "$STATUS"
}

# ---------------------------------------------------------------- install
remove_old_pages() {
	local f
	for f in "$WWW"/user*.asp; do
		[ -f "$f" ] || continue
		grep -q 'auractrl_status.js' "$f" || continue
		cmp -s "$f" "$PAGE" && continue
		rm -f "$f" && log "removed old WebUI page ${f##*/}"
	done
}
install_page() {
	local trust=$1
	load_static refresh; load_model
	[ $AURA = 1 ] || log "WARNING: rc_support has no aura_rgb - this router may not have an Aura RGB logo"
	[ -d "$RUN" ] || mkdir -p "$RUN"
	remove_old_pages
	am_get_webui_page "$PAGE"
	if [ "$am_webui_page" = "none" ]; then log "no free WebUI page slot"; return 1; fi
	cp "$PAGE" "$WWW/$am_webui_page"
	if [ ! -f /tmp/menuTree.js ]; then
		cp /www/require/modules/menuTree.js /tmp/
		mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
	fi
	sed -i '/tabName: "Aura-CTRL"/d' /tmp/menuTree.js
	sed -i "/url: \"Tools_OtherSettings.asp\", tabName:/a {url: \"$am_webui_page\", tabName: \"Aura-CTRL\"}," /tmp/menuTree.js
	grep -q 'tabName: "Aura-CTRL"' /tmp/menuTree.js || \
		sed -i "/url: \"Advanced_System_Content.asp\", tabName:/a {url: \"$am_webui_page\", tabName: \"Aura-CTRL\"}," /tmp/menuTree.js
	umount /www/require/modules/menuTree.js 2>/dev/null
	mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
	# original Aura values (saved once, restored by uninstall)
	[ -f "$ORIG" ] || { nvg aurargb_enable; local en=$V; echo "$en $(nvram get aurargb_val)" > "$ORIG"; }
	cru d auractrl_check 2>/dev/null
	cru a auractrl_check "* * * * * $SELF check"
	# after the cron job is added: installing (not the boot) makes this configuration the trusted one
	if [ "$trust" = trust ] || [ ! -f "$FPRINT" ]; then fingerprint; echo "$FP" > "$FPRINT"; rm -f "$RUN/a/tamper".* "$RUN/tamper.last"; fi
	log "Aura-CTRL $VERSION: WebUI page installed as $am_webui_page (Administration > Aura-CTRL)"
	rm -f "$RUN/plan"
	do_check
}
do_startup() {
	[ -d "$RUN" ] || mkdir -p "$RUN"
	: > "$RUN/booting"; rm -f "$RUN/plan" "$RUN/usb.base"
	install_page
	(
		# booting ends when the clock is synchronised and the router has been up 60 s (at most 3 minutes)
		n=0
		while [ $n -lt 36 ]; do
			[ "$(nvram get ntp_ready)" = 1 ] && { uptime_s; [ $UP -ge 60 ]; } && break
			sleep 5; n=$((n + 1))
		done
		rm -f "$RUN/booting"
		"$SELF" check
	) >/dev/null 2>&1 &
}
uninstall_page() {
	stop_worker
	am_get_webui_page "$PAGE"
	[ "$am_webui_page" != "none" ] && rm -f "$WWW/$am_webui_page"
	if [ -f /tmp/menuTree.js ]; then
		sed -i '/tabName: "Aura-CTRL"/d' /tmp/menuTree.js
		umount /www/require/modules/menuTree.js 2>/dev/null
		mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
	fi
	cru d auractrl_check 2>/dev/null
	rm -f "$STATUS"; rm -rf "$RUN"
	sed -i '/aura-ctrl/d' /jffs/scripts/service-event /jffs/scripts/services-start /jffs/scripts/wan-event 2>/dev/null
	if [ -f "$ORIG" ]; then
		readf "$ORIG"; set -- $V
		[ -n "$1" ] && nvram set aurargb_enable="$1"; [ -n "$2" ] && nvram set aurargb_val="$2"
	fi
	service restart_leds >/dev/null 2>&1
	log "uninstalled (files kept in $ADDIR: rm -r $ADDIR to delete them)"
}

# ---------------------------------------------------------------- main
# event hooks only start the real work in the background: nothing to load for them
case "$1" in
	event)
		case "$3" in
			auractrl) [ -d "$RUN" ] && rm -f "$RUN/plan"; "$SELF" check >/dev/null 2>&1 & ;;
			auractrlack) "$SELF" ack >/dev/null 2>&1 & ;;
			auractrltest*) "$SELF" test "${3#auractrltest}" >/dev/null 2>&1 & ;;
			auractrlident*) x=${3#auractrlident}; "$SELF" identify "${x%"${x#?}"}" "${x#?}" >/dev/null 2>&1 & ;;
			auractrlcal*)   # auractrlcal<rrggbb><rrr><ggg><bbb>
				x=${3#auractrlcal}; y=${x#??????}; t=${y#???}
				"$SELF" calib "${x%?????????}" "${y%??????}" "${t%???}" "${y#??????}" >/dev/null 2>&1 & ;;
			auractrlfam*)   # auractrlfam<rrr><ggg><bbb>
				x=${3#auractrlfam}; t=${x#???}
				"$SELF" colours "${x%??????}" "${t%???}" "${x#??????}" >/dev/null 2>&1 & ;;
			auractrlstatus) "$SELF" status >/dev/null 2>&1 & ;;
			wireless) rm -f "$RUN/nv.cache" ;;   # Wi-Fi settings may have changed: read them again
		esac
		exit 0 ;;
	wanevent) case "$3" in connected|disconnected|stopped) "$SELF" check >/dev/null 2>&1 & ;; esac; exit 0 ;;
	version) echo "Aura-CTRL $VERSION"; exit 0 ;;
esac

clock; uptime_s; load_settings; load_static; load_model; load_light; load_options
trim_events

case "$1" in
	install) install_page trust ;;
	startup) do_startup ;;
	check) do_check ;;
	worker) worker "$2" "$3" ;;
	ack) do_ack ;;
	test) do_test "$2" ;;
	identify) do_identify "$2" "$3" ;;
	colours) do_colours "$2" "$3" "$4" ;;
	calib) do_calib "$2" "$3" "$4" "$5" ;;
	effect) do_effect "$2" "$3" ;;
	status) write_status ;;
	uninstall) uninstall_page ;;
	*) echo "Aura-CTRL $VERSION - usage: $0 install | startup | check | event <action> <service> | wanevent <unit> <event> | ack | test <alert> | identify <zone> [seconds] | colours [r g b] | calib <rrggbb> [r g b] | effect <0-13|end> [rrggbb] | status | version | uninstall" ;;
esac
