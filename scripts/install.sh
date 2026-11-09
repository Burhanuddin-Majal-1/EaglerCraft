#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="$ROOT/server"
PROXY_DIR="$ROOT/proxy"

: "${MC_VERSION:=26.2}"
: "${EAGLERXSERVER_VERSION:=1.1.1}"
: "${PAPERMC_USER_AGENT:=EaglerCraft-Server/1.0 (GitHub project)}"

command -v curl >/dev/null || { echo "ERROR: curl is required"; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq is required"; exit 1; }
command -v java >/dev/null || { echo "ERROR: Java 25 or newer is required"; exit 1; }

JAVA_MAJOR="$(java -version 2>&1 | awk -F '[."]' '/version/ { if ($2 == "1") print $3; else print $2; exit }')"
if [[ -z "$JAVA_MAJOR" || "$JAVA_MAJOR" -lt 25 ]]; then
  echo "ERROR: Minecraft 26.3 requires Java 25 or newer. Detected: ${JAVA_MAJOR:-unknown}"
  exit 1
fi

mkdir -p "$SERVER_DIR/plugins" "$SERVER_DIR/config" "$PROXY_DIR/plugins" "$ROOT/web"

echo "==> Resolving latest stable Paper build for Minecraft $MC_VERSION"
PAPER_BUILDS="$(curl -fsSL -H "User-Agent: $PAPERMC_USER_AGENT" \
  "https://fill.papermc.io/v3/projects/paper/versions/$MC_VERSION/builds")"
PAPER_URL="$(jq -r 'first(.[] | select(.channel == "STABLE") | .downloads."server:default".url) // empty' <<<"$PAPER_BUILDS")"

if [[ -z "$PAPER_URL" || "$PAPER_URL" == "null" ]]; then
  echo "ERROR: No stable Paper build is currently available for Minecraft $MC_VERSION."
  echo "Check https://papermc.io/downloads/paper and try again later."
  exit 1
fi

curl -fL --retry 3 "$PAPER_URL" -o "$SERVER_DIR/paper.jar"

echo "==> Resolving latest Velocity build (PaperMC Fill API v3)"
VELOCITY_META="$(curl -fsSL -H "User-Agent: $PAPERMC_USER_AGENT" \
  "https://fill.papermc.io/v3/projects/velocity")"
VELOCITY_VERSION="$(jq -r '.versions | to_entries[0].value[0] // empty' <<<"$VELOCITY_META")"
[[ -n "$VELOCITY_VERSION" && "$VELOCITY_VERSION" != "null" ]] || {
  echo "ERROR: Could not resolve an available Velocity version"
  exit 1
}

VELOCITY_BUILDS="$(curl -fsSL -H "User-Agent: $PAPERMC_USER_AGENT" \
  "https://fill.papermc.io/v3/projects/velocity/versions/$VELOCITY_VERSION/builds")"
VELOCITY_BUILD="$(jq -r 'first(.[] | select(.channel == "STABLE") | .id) // empty' <<<"$VELOCITY_BUILDS")"
VELOCITY_URL="$(jq -r 'first(.[] | select(.channel == "STABLE") | .downloads."server:default".url) // empty' <<<"$VELOCITY_BUILDS")"

if [[ -z "$VELOCITY_BUILD" || -z "$VELOCITY_URL" || "$VELOCITY_URL" == "null" ]]; then
  echo "ERROR: No stable Velocity build/download URL found for version $VELOCITY_VERSION."
  echo "PaperMC response (first 1000 chars):"
  printf '%s' "$VELOCITY_BUILDS" | head -c 1000
  exit 1
fi

curl -fL --retry 3 -H "User-Agent: $PAPERMC_USER_AGENT" "$VELOCITY_URL" -o "$PROXY_DIR/velocity.jar"

echo "==> Downloading EaglerXServer $EAGLERXSERVER_VERSION for Velocity"
EAGLERX_URL="https://github.com/lax1dude/eaglerxserver/releases/download/v$EAGLERXSERVER_VERSION/EaglerXServer.jar"
curl -fL --retry 3 "$EAGLERX_URL" -o "$PROXY_DIR/plugins/EaglerXServer.jar"

printf '\nInstalled:\nPaper Minecraft %s (latest stable build)\nVelocity %s build %s\nEaglerXServer %s\n' \
  "$MC_VERSION" "$VELOCITY_VERSION" "$VELOCITY_BUILD" "$EAGLERXSERVER_VERSION"
echo "Java detected: $JAVA_MAJOR"
echo "Next: boot once to generate configs, then follow the port/forwarding setup in README.md."
