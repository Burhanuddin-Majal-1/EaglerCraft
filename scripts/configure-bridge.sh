#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="$ROOT/proxy/plugins"

command -v python3 >/dev/null || {
  echo "ERROR: python3 is required to configure the EaglerXServer listener."
  exit 1
}

CONFIG="$(find "$PLUGIN_DIR" -type f \( -iname 'listeners.yaml' -o -iname 'listeners.yml' \) -print -quit 2>/dev/null || true)"
if [[ -z "$CONFIG" ]]; then
  echo "ERROR: EaglerXServer listeners.yaml was not found."
  echo "Run ./scripts/start.sh once, wait for Velocity to finish loading, then run ./scripts/stop.sh."
  echo "After the plugin has generated its config, run this script again."
  exit 1
fi

python3 - "$CONFIG" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
if re.search(r'(?m)^\s*-\s*listener_name:\s*eaglercraft-8082\s*$', text):
    print(f"Bridge listener already exists in {path}")
    raise SystemExit(0)

# EaglerXServer's Velocity config uses a listener_list YAML sequence.
match = re.search(r'(?m)^listener_list:\s*(?:\[\s*\])?\s*$', text)
if not match:
    raise SystemExit(
        f"ERROR: listener_list was not found in {path}. "
        "No changes were made; inspect the generated config before editing it."
    )

key_line_end = match.end()
entry = (
    "\n  - listener_name: eaglercraft-8082"
    "\n    inject_address: \"0.0.0.0:8082\""
    "\n    velocity_clone_listener: true"
    "\n    dual_stack: true"
)

# If the sequence was written as an inline empty list, expand it first.
prefix = text[:match.start()]
suffix = text[key_line_end:]
if "[]" in match.group(0):
    replacement = "listener_list:"
    text = prefix + replacement + entry + suffix
else:
    # Insert before the next top-level YAML key, or at end of file.
    next_key = re.search(r'(?m)^[A-Za-z0-9_-]+\s*:', suffix)
    if next_key:
        insert_at = key_line_end + next_key.start()
        text = text[:insert_at].rstrip() + entry + "\n" + text[insert_at:]
    else:
        text = text.rstrip() + entry + "\n"

path.write_text(text, encoding="utf-8")
print(f"Configured Eaglercraft WebSocket listener on 0.0.0.0:8082 in {path}")
PY

echo "Done. Restart the network with ./scripts/start.sh"
