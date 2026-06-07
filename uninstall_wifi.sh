#!/bin/bash
# Backward-compatible wrapper. WiFi cleanup is now part of uninstall_droidklipp.sh.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "WiFi cleanup is now included in uninstall_droidklipp.sh."
echo "Running uninstall_droidklipp.sh..."
exec bash "$SCRIPT_DIR/uninstall_droidklipp.sh" "$@"
