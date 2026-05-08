#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════
#  AEON Dispatch — Uninstall
# ═══════════════════════════════════════════════════════════

BIN_DIR="$HOME/.local/bin"
APP_NAME="AEON Dispatch"
INSTALL_DIR="$HOME/Applications"
DISPATCH_HOME="$HOME/.aeon-dispatch"
LAUNCH_AGENT_ID="com.aeon.dispatch"
LAUNCH_AGENT_PLIST="$HOME/Library/LaunchAgents/$LAUNCH_AGENT_ID.plist"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

info()  { echo -e "  $1"; }
ok()    { echo -e "  ${GREEN}✓${RESET} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${RESET} $1"; }

echo ""
echo -e "${BOLD}═══════════════════════════════════════════${RESET}"
echo -e "${BOLD}  ⚡ AEON Dispatch — Uninstall${RESET}"
echo -e "${BOLD}═══════════════════════════════════════════${RESET}"
echo ""

# Stop the app if running
if pgrep -x "AEONDispatch" &>/dev/null; then
    pkill -x "AEONDispatch" 2>/dev/null || true
    ok "Stopped running AEON Dispatch"
fi

# Remove LaunchAgent
if [[ -f "$LAUNCH_AGENT_PLIST" ]]; then
    launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_PLIST" 2>/dev/null || true
    rm -f "$LAUNCH_AGENT_PLIST"
    ok "Removed LaunchAgent"
fi

# Remove launchd scheduler plist (dispatch install creates this one)
SCHED_PLIST="$HOME/Library/LaunchAgents/com.aeon.dispatch.scheduler.plist"
if [[ -f "$SCHED_PLIST" ]]; then
    launchctl bootout "gui/$(id -u)" "$SCHED_PLIST" 2>/dev/null || true
    rm -f "$SCHED_PLIST"
    ok "Removed scheduler LaunchAgent"
fi

# Remove app bundle
if [[ -d "$INSTALL_DIR/$APP_NAME.app" ]]; then
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
    ok "Removed $INSTALL_DIR/$APP_NAME.app"
fi

# Remove CLI scripts
removed=0
for script in dispatch aeon-dispatch-control; do
    if [[ -f "$BIN_DIR/$script" ]]; then
        rm -f "$BIN_DIR/$script"
        ((removed++))
    fi
done
ok "Removed $removed scripts from $BIN_DIR"

echo ""
echo -e "${GREEN}${BOLD}  Uninstall complete.${RESET}"
echo ""
echo "  Note: Your data is preserved at $DISPATCH_HOME/"
echo "  This includes flows, customizations, results, and config."
echo ""
echo "  To remove everything: rm -rf $DISPATCH_HOME"
echo ""
