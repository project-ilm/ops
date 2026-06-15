#!/usr/bin/env bash
# ilmd.sh — tiny detached task runner. start | add "<cmd>" | status | stop. context: https://ilm.codes/context/
set -uo pipefail
W=~/work/11jun; OPS="$W/ops"; Q="$OPS/queue.txt"; ST="$OPS/ilmd.status"; LOGD="$OPS/logs"
mkdir -p "$LOGD"; touch "$Q"
case "${1:-status}" in
 start) if command -v screen >/dev/null 2>&1; then screen -dmS ilmd bash "$0" worker; echo "ilmd started — attach: screen -r ilmd"
        else setsid nohup bash "$0" worker >"$LOGD/ilmd.out" 2>&1 & echo "ilmd started — pid $!"; fi ;;
 add)  shift; printf '%s\n' "$*" >> "$Q"; echo "queued: $*" ;;
 status) echo "[status] $(cat "$ST" 2>/dev/null || echo idle)"; echo "[queue] $(wc -l <"$Q") pending"; cat "$Q";
         f=$(ls -t "$LOGD"/ilmd-*.log 2>/dev/null | head -1); [ -n "$f" ] && { echo "[last log] $f"; tail -n 10 "$f"; } ;;
 stop) screen -S ilmd -X quit 2>/dev/null || pkill -f "ilmd.sh worker" 2>/dev/null || true; echo "stopped" ;;
 worker) while true; do
     line=$(head -n1 "$Q" 2>/dev/null || true)
     [ -z "$line" ] && { echo "idle $(date)" >"$ST"; sleep 5; continue; }
     sed -i '1d' "$Q"; log="$LOGD/ilmd-$(date +%Y%m%d-%H%M%S).log"
     echo "running: $line ($(date))" >"$ST"; { echo "+ $line"; bash -lc "$line"; echo "rc=$?"; } >"$log" 2>&1
     echo "done: $line rc=$? ($(date))" >"$ST"; done ;;
 *) echo "usage: ilmd.sh {start|add <cmd>|status|stop}";;
esac
