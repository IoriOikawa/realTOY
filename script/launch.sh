#!/bin/bash

set -eo pipefail

MY="$(realpath "$(dirname "$0")")"

TCL="$1"
shift
SCR="$(basename "$TCL")"
mkdir -p build/report/
if [ "$TCL" = "script/synth_ip.tcl" ]; then
    IP_NAME="$(basename "$1")"
    IP_NAME="${IP_NAME%.*}"
    rm -rf "build/ip/$IP_NAME/"
    mkdir -p "build/ip/$IP_NAME/"
    cp -f "$1" "build/ip/$IP_NAME/"

    LOG="${SCR%.*}_$IP_NAME.log"
    export IP_NAME
elif [ "$TCL" = "script/synth.tcl" ]; then
    IP_NAMES=""
    while [ "$#" -gt 0 ]; do
        if grep -q '/' <<<"$1"; then
            IP_NAME="ip/$1"
        else
            IP_NAME="ip/$1/$1.xci"
        fi
        [ -z "$IP_NAMES" ] && IP_NAMES="$IP_NAME" || IP_NAMES="$IP_NAMES $IP_NAME"
        shift
    done
    LOG="${SCR%.*}.log"
    export IP_NAMES
elif [ "$TCL" = "script/fsbl.tcl" ]; then
    mkdir -p "build/fsbl/"
    LOG="${SCR%.*}.log"
else
    LOG="${SCR%.*}.log"
fi

cd build/

finish() {
    printf '\e[31mERROR: Vivado failed. Log file: ./build/%s\e[0m\n' "$LOG"
}
trap finish EXIT

(
if [ "$TCL" = "script/synth_ip.tcl" ]; then
    printf '# PART=%s\n' "$PART"
    printf '# IP_NAME=%s\n' "$IP_NAME"
elif [ "$TCL" = "script/synth.tcl" ]; then
    printf '# PART=%s\n' "$PART"
    printf '# IP_NAMES=%s\n' "$IP_NAMES"
fi
"$VIVADO/bin/vivado" -nojournal -nolog -mode batch -source "../$TCL" 2>&1
) | tee "$LOG" | "$MY/log_highlight.sh"
trap - EXIT
