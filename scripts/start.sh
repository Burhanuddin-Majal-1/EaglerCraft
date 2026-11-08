#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="$ROOT/server"
PROXY_DIR="$ROOT/proxy"

: "${PAPER_RAM:=2G}"
: "${VELOCITY_RAM:=1G}"

for file in "$SERVER_DIR/paper.jar" "$PROXY_DIR/velocity.jar"; do
  [[ -f "$file" ]] || { echo "Missing $file — run scripts/install.sh first."; exit 1; }
done

if [[ -f "$SERVER_DIR/paper.pid" ]] || [[ -f "$PROXY_DIR/velocity.pid" ]]; then
  echo "A PID file already exists. Run scripts/stop.sh and check processes before restarting."
  exit 1
fi

cd "$SERVER_DIR"
nohup java -Xms1G -Xmx"$PAPER_RAM" -jar paper.jar --nogui > paper-console.log 2>&1 &
echo $! > paper.pid

sleep 3
cd "$PROXY_DIR"
nohup java -Xms256M -Xmx"$VELOCITY_RAM" -jar velocity.jar > velocity-console.log 2>&1 &
echo $! > velocity.pid

echo "Paper and Velocity launched. Logs: server/paper-console.log and proxy/velocity-console.log"
