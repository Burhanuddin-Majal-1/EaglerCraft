#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

find_listener_config() {
  find "$ROOT/proxy/plugins" -type f \( -iname 'listeners.yaml' -o -iname 'listeners.yml' \) -print -quit 2>/dev/null || true
}

if [[ -f server/paper.pid || -f proxy/velocity.pid ]]; then
  echo "ERROR: PID files show the network may already be running."
  echo "Run ./scripts/stop.sh first, then retry this command."
  exit 1
fi

if [[ ! -f server/paper.jar || ! -f proxy/velocity.jar || ! -f proxy/plugins/EaglerXServer.jar ]]; then
  echo "==> Server/plugin files missing; installing the configured 26.2 stack"
  ./scripts/install.sh
fi

CONFIG="$(find_listener_config)"
if [[ -z "$CONFIG" ]]; then
  echo "==> First boot: starting Paper and Velocity so EaglerXServer can generate listeners.yaml"
  ./scripts/start.sh

  for attempt in {1..30}; do
    CONFIG="$(find_listener_config)"
    [[ -n "$CONFIG" ]] && break
    sleep 2
  done

  if [[ -z "$CONFIG" ]]; then
    echo "ERROR: EaglerXServer did not generate listeners.yaml within 60 seconds."
    echo "Recent Velocity log output:"
    tail -n 60 proxy/velocity-console.log 2>/dev/null || true
    ./scripts/stop.sh || true
    exit 1
  fi

  PAPER_PID="$(cat server/paper.pid 2>/dev/null || true)"
  VELOCITY_PID="$(cat proxy/velocity.pid 2>/dev/null || true)"
  ./scripts/stop.sh

  for pid in "$VELOCITY_PID" "$PAPER_PID"; do
    [[ -n "$pid" ]] || continue
    for attempt in {1..15}; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 1
    done
  done
fi

echo "==> Configuring the Eaglercraft WebSocket listener"
./scripts/configure-bridge.sh

echo "==> Starting the network with the 8082 bridge enabled"
./scripts/start.sh

echo
echo "Network start requested."
echo "Eaglercraft WebSocket: port 8082"
echo "Java Edition:          port 25565"
echo "Private Paper backend: port 25566 (do not expose)"
echo "Logs: proxy/velocity-console.log and server/paper-console.log"
