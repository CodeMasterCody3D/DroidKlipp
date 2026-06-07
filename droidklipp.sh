#!/bin/bash
# Backward-compatible wrapper. The real installer was renamed for clarity.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "DroidKlipp installer has been renamed to install_droidklipp.sh."
echo "Running install_droidklipp.sh..."
exec bash "$SCRIPT_DIR/install_droidklipp.sh" "$@"
