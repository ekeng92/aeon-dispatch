#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════
#  AEON Dispatch — Complete Installation
#  Works on any Mac with macOS 13+ and Xcode CommandLineTools
# ═══════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Support AEON_PREFIX for dry-run / sandboxed installs
AEON_HOME="${AEON_PREFIX:-$HOME}"
BIN_DIR="$AEON_HOME/.local/bin"
DISPATCH_HOME="$AEON_HOME/.aeon-dispatch"
APP_NAME="AEON Dispatch"
INSTALL_DIR="$AEON_HOME/Applications"
LAUNCH_AGENT_DIR="$AEON_HOME/Library/LaunchAgents"
LAUNCH_AGENT_ID="com.aeon.dispatch"
LAUNCH_AGENT_PLIST="$LAUNCH_AGENT_DIR/$LAUNCH_AGENT_ID.plist"

# Parse flags
NON_INTERACTIVE=false
for arg in "$@"; do
    case "$arg" in
        --non-interactive) NON_INTERACTIVE=true ;;
    esac
done

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

info()  { echo "  ${CYAN}▸${RESET} $1"; }
ok()    { echo "  ${GREEN}✓${RESET} $1"; }
warn()  { echo "  ${YELLOW}⚠${RESET} $1"; }
fail()  { echo "  ${RED}✗${RESET} $1"; exit 1; }

echo ""
echo "${BOLD}═══════════════════════════════════════════${RESET}"
echo "${BOLD}  ⚡ AEON Dispatch — Installation${RESET}"
echo "${BOLD}═══════════════════════════════════════════${RESET}"
echo ""

if [[ -n "${AEON_PREFIX:-}" ]]; then
    warn "DRY RUN MODE — installing to $AEON_HOME (not your real home)"
    echo ""
fi

# ── Step 1: Check macOS version ────────────────────────────────────────

info "Checking macOS version..."
MACOS_VERSION="$(sw_vers -productVersion)"
MAJOR="$(echo "$MACOS_VERSION" | cut -d. -f1)"
if (( MAJOR < 13 )); then
    fail "macOS 13 (Ventura) or later required. You have $MACOS_VERSION."
fi
ok "macOS $MACOS_VERSION"

# ── Step 2: Check Swift toolchain ──────────────────────────────────────

info "Checking Swift toolchain..."
if ! command -v swift &>/dev/null; then
    fail "Swift not found. Install Xcode CommandLineTools: xcode-select --install"
fi
SWIFT_VERSION="$(swift --version 2>&1 | head -1)"
ok "$SWIFT_VERSION"

# ── Step 3: Check jq ──────────────────────────────────────────────────

info "Checking jq..."
if ! command -v jq &>/dev/null; then
    warn "jq not found. Installing via Homebrew..."
    if command -v brew &>/dev/null; then
        brew install jq --quiet
        ok "jq installed"
    else
        fail "jq is required. Install via: brew install jq"
    fi
else
    ok "jq available"
fi

# ── Step 4: Find Copilot CLI ──────────────────────────────────────────

info "Looking for Copilot CLI..."
COPILOT_PATH=""
if command -v copilot &>/dev/null; then
    COPILOT_PATH="$(command -v copilot)"
elif [[ -n "${NVM_DIR:-}" ]]; then
    NODE_VERSION="$(node -v 2>/dev/null || true)"
    if [[ -n "$NODE_VERSION" && -f "$NVM_DIR/versions/node/$NODE_VERSION/bin/copilot" ]]; then
        COPILOT_PATH="$NVM_DIR/versions/node/$NODE_VERSION/bin/copilot"
    fi
fi

if [[ -n "$COPILOT_PATH" ]]; then
    ok "Copilot CLI: $COPILOT_PATH"
else
    warn "Copilot CLI not found. You can set DISPATCH_COPILOT in ~/.aeon-dispatch/config.sh later."
    COPILOT_PATH="copilot"
fi

# ── Step 5: Create user data directories ──────────────────────────────

info "Setting up ~/.aeon-dispatch/..."
mkdir -p "$DISPATCH_HOME/flows" "$DISPATCH_HOME/customizations" "$DISPATCH_HOME/results" "$DISPATCH_HOME/logs"
ok "Data directories ready"

# ── Step 6: Generate config (only if new) ─────────────────────────────

if [[ ! -f "$DISPATCH_HOME/config.sh" ]]; then
    cat > "$DISPATCH_HOME/config.sh" << CONFIG
# aeon-dispatch configuration
# Edit this file to customize behavior.

# Path to copilot CLI binary (auto-detected during install)
DISPATCH_COPILOT="$COPILOT_PATH"

# Send macOS notifications on flow completion
DISPATCH_NOTIFY=true

# Editor for viewing results (used by 'dispatch open')
DISPATCH_EDITOR="${EDITOR:-code}"
CONFIG
    ok "Config created: $DISPATCH_HOME/config.sh"
else
    ok "Config exists (preserved): $DISPATCH_HOME/config.sh"
fi

# ── Step 7: Install example flows (only if flows dir is empty) ────────

FLOW_COUNT=$(find "$DISPATCH_HOME/flows" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
if (( FLOW_COUNT == 0 )); then
    if [[ -d "$PROJECT_DIR/examples" ]]; then
        for example in "$PROJECT_DIR"/examples/*.json; do
            [[ ! -f "$example" ]] && continue
            cp "$example" "$DISPATCH_HOME/flows/"
        done
        ok "Example flows installed ($(ls "$PROJECT_DIR"/examples/*.json 2>/dev/null | wc -l | tr -d ' ') flows)"
    fi
else
    ok "Existing flows preserved ($FLOW_COUNT flows)"
fi

# ── Step 8: Build the app ─────────────────────────────────────────────

info "Building AEON Dispatch (compiling from source)..."
cd "$PROJECT_DIR"
make app 2>&1 | while IFS= read -r line; do
    echo "    ${DIM}$line${RESET}"
done
echo ""

# ── Step 9: Install app bundle ────────────────────────────────────────

info "Installing app to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
if pgrep -x AEONDispatch >/dev/null 2>&1; then
    info "Stopping running instance..."
    osascript -e 'quit app "AEON Dispatch"' >/dev/null 2>&1 || pkill -x AEONDispatch 2>/dev/null || true
    sleep 1
fi
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "build/$APP_NAME.app" "$INSTALL_DIR/"
codesign --force --deep --sign - "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true
touch "$INSTALL_DIR/$APP_NAME.app"
rm -rf "$PROJECT_DIR/build" 2>/dev/null || true
ok "App installed: $INSTALL_DIR/$APP_NAME.app"

# ── Step 10: Install dispatch CLI ─────────────────────────────────────

info "Installing CLI to $BIN_DIR..."
mkdir -p "$BIN_DIR"
cp "$PROJECT_DIR/dispatch" "$BIN_DIR/dispatch"
chmod +x "$BIN_DIR/dispatch"
ok "CLI installed: $BIN_DIR/dispatch"

# Create convenience launcher
cat > "$BIN_DIR/aeon-dispatch-control" << LAUNCHER
#!/bin/zsh
open "$INSTALL_DIR/$APP_NAME.app"
LAUNCHER
chmod +x "$BIN_DIR/aeon-dispatch-control"

# ── Step 11: Ensure ~/.local/bin is in PATH ───────────────────────────

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    warn "$BIN_DIR is not in PATH"
    echo ""
    echo "    Add to your shell profile (~/.zshrc or ~/.bashrc):"
    echo ""
    echo "      export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# ── Step 12: Optional LaunchAgent ─────────────────────────────────────

if [[ -n "${AEON_PREFIX:-}" ]]; then
    info "Skipping LaunchAgent (dry-run mode)"
    REPLY="n"
elif [[ "$NON_INTERACTIVE" == "true" ]]; then
    REPLY="y"
else
    echo ""
    read -p "  Start AEON Dispatch automatically on login? [y/N] " -n 1 -r < /dev/tty
    echo ""
fi

if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p "$LAUNCH_AGENT_DIR"
    cat > "$LAUNCH_AGENT_PLIST" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LAUNCH_AGENT_ID</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/$APP_NAME.app/Contents/MacOS/AEONDispatch</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
PLIST
    launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_PLIST" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_PLIST"
    ok "LaunchAgent installed — AEON Dispatch will start on login"
    ok "App launched (via LaunchAgent)"
else
    info "Skipped LaunchAgent. Start manually: open '$INSTALL_DIR/$APP_NAME.app'"
fi

# ── Step 13: Launch the app (only if LaunchAgent didn't start it) ─────

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    open "$INSTALL_DIR/$APP_NAME.app"
    ok "App launched"
fi

# ── Done ──────────────────────────────────────────────────────────────

echo ""
echo "${BOLD}═══════════════════════════════════════════${RESET}"
echo "${GREEN}${BOLD}  ⚡ Installation complete!${RESET}"
echo "${BOLD}═══════════════════════════════════════════${RESET}"
echo ""
echo "  App:       $INSTALL_DIR/$APP_NAME.app"
echo "  CLI:       $BIN_DIR/dispatch"
echo "  Data:      $DISPATCH_HOME/"
echo "  Flows:     $DISPATCH_HOME/flows/"
echo "  Results:   $DISPATCH_HOME/results/"
echo ""
echo "  ${BOLD}Quick start:${RESET}"
echo "    dispatch list              # see your flows"
echo "    dispatch run <flow>        # run one now"
echo "    dispatch install           # enable launchd scheduler"
echo ""
echo "  ${BOLD}Menu bar:${RESET}"
echo "    Click the ⚡ icon in the menu bar"
echo ""
