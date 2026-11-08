#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

stop_process() {
  local pid_file="$1"
  local label="$2"
  if [[ ! -f "$pid_file" ]]; then
    echo "$label: no PID file"
    return
  fi
  local pid
  pid="$(cat "$pid_file")"
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid"
    echo "$label: stop signal sent to $pid"
  else
    echo "$label: process $pid is not running"
  fi
  rm -f "$pid_file"
}

stop_process "$ROOT/proxy/velocity.pid" "Velocity"
stop_process "$ROOT/server/paper.pid" "Paper"
