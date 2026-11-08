#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="$ROOT/server"
PROXY_DIR="$ROOT/proxy"

: "${MC_VERSION:?Set MC_VERSION to a Minecraft backend version supported by your planned Eaglercraft bridge}"

command -v curl >/dev/null || { echo "ERROR: curl is required"; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq is required"; exit 1; }

mkdir -p "$SERVER_DIR/plugins" "$SERVER_DIR/config" "$PROXY_DIR/plugins" "$ROOT/web"

echo "==> Resolving Paper build for Minecraft $MC_VERSION"
PAPER_META="$(curl -fsSL "https://api.papermc.io/v2/projects/paper/versions/$MC_VERSION")"
PAPER_BUILD="$(jq -r '.builds[-1]' <<<"$PAPER_META")"
[[ "$PAPER_BUILD" != "null" && -n "$PAPER_BUILD" ]] || {
  echo "ERROR: No Paper build found for Minecraft $MC_VERSION"
  exit 1
}

PAPER_BUILD_META="$(curl -fsSL "https://api.papermc.io/v2/projects/paper/versions/$MC_VERSION/builds/$PAPER_BUILD")"
PAPER_NAME="$(jq -r '.downloads.application.name' <<<"$PAPER_BUILD_META")"
curl -fL --retry 3   "https://api.papermc.io/v2/projects/paper/versions/$MC_VERSION/builds/$PAPER_BUILD/downloads/$PAPER_NAME"   -o "$SERVER_DIR/paper.jar"

echo "==> Resolving latest Velocity build"
VELOCITY_META="$(curl -fsSL "https://api.papermc.io/v2/projects/velocity")"
VELOCITY_VERSION="$(jq -r '.versions[-1]' <<<"$VELOCITY_META")"
[[ "$VELOCITY_VERSION" != "null" && -n "$VELOCITY_VERSION" ]] || {
  echo "ERROR: Could not resolve a Velocity version"
  exit 1
}
VELOCITY_VERSION_META="$(curl -fsSL "https://api.papermc.io/v2/projects/velocity/versions/$VELOCITY_VERSION")"
VELOCITY_BUILD="$(jq -r '.builds[-1]' <<<"$VELOCITY_VERSION_META")"
VELOCITY_BUILD_META="$(curl -fsSL "https://api.papermc.io/v2/projects/velocity/versions/$VELOCITY_VERSION/builds/$VELOCITY_BUILD")"
VELOCITY_NAME="$(jq -r '.downloads.application.name' <<<"$VELOCITY_BUILD_META")"
curl -fL --retry 3   "https://api.papermc.io/v2/projects/velocity/versions/$VELOCITY_VERSION/builds/$VELOCITY_BUILD/downloads/$VELOCITY_NAME"   -o "$PROXY_DIR/velocity.jar"

printf '\nInstalled:\nPaper %s build %s\nVelocity %s build %s\n' \
  "$MC_VERSION" "$PAPER_BUILD" "$VELOCITY_VERSION" "$VELOCITY_BUILD"
echo "Next: configure Velocity forwarding and Paper's proxy settings before opening the network."
