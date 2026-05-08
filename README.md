# AEON Dispatch

A native macOS menu bar app for orchestrating GitHub Copilot CLI workflows. Define reusable customizations (agent + model + working directory), compose them into flows with prompt files, schedule runs, and see results, all from your menu bar.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange) ![License: MIT](https://img.shields.io/badge/License-MIT-green)

## Features

- **Customizations** - Reusable execution profiles: agent, model, working directory, prompt file
- **Flows** - Composable dispatch units that reference a customization or define inline settings
- **Scheduling** - Cron-based LaunchAgent scheduler for automated flow execution
- **Results** - View recent dispatch results with status, duration, and output
- **Self-updating** - Check for updates and reinstall from GitHub without losing your configuration
- **CLI** - `dispatch` command for terminal-based flow execution

## Install

One command:

```bash
curl -fsSL https://raw.githubusercontent.com/ekeng92/aeon-dispatch/main/scripts/remote-install.sh | bash
```

This will:
1. Verify prerequisites (macOS 13+, Swift, Git, GitHub Copilot CLI)
2. Clone the repo, build from source, and install to `~/Applications/`
3. Install the `dispatch` CLI to `~/.local/bin/`
4. Optionally set up a LaunchAgent for scheduled flows

### Prerequisites

- macOS 13 (Ventura) or later
- Swift toolchain (comes with Xcode or Xcode Command Line Tools)
- Git
- [GitHub Copilot CLI](https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-in-the-command-line) (`github-copilot-cli` or `copilot` on PATH)

## What Gets Installed

| Item | Location | Purpose |
|------|----------|---------|
| App bundle | `~/Applications/AEON Dispatch.app` | Menu bar app |
| CLI | `~/.local/bin/dispatch` | Terminal dispatch command |
| User data | `~/.aeon-dispatch/` | Flows, customizations, results, config, logs |
| LaunchAgent (optional) | `~/Library/LaunchAgents/com.aeon.dispatch.plist` | Scheduled flow execution |

## Usage

### Customizations

Customizations are reusable execution profiles stored as JSON in `~/.aeon-dispatch/customizations/`. Each defines:

- **Agent** - The Copilot agent to use (e.g., `aeon-dev-lead`)
- **Model** - The LLM model (e.g., `Claude Sonnet 4`)
- **Working Directory** - Where the agent runs
- **Prompt File** - Default prompt file path

Create and manage customizations from the app's purple "Customizations" section, or place JSON files directly in the directory.

### Flows

Flows are dispatch units stored in `~/.aeon-dispatch/flows/`. A flow can reference a customization (inheriting its settings) or define agent/model/workdir inline. Each flow has:

- **Prompt** - Inline text or a path to a `.prompt.md` file
- **Customization** (optional) - References a customization for execution context
- **Schedule** (optional) - Cron expression for automated execution

### CLI

```bash
# Run a flow
dispatch run my-flow

# List flows
dispatch list

# Show status
dispatch status
```

### Scheduling

The app can install a LaunchAgent that runs the dispatch scheduler every 5 minutes. Flows with a `schedule` field are executed automatically based on their cron expression. Enable/disable from the "Actions" section in the menu bar popover.

## Updating

The app checks for updates on launch. When a new version is available, click "Update Now" in the menu bar popover. The update process:

1. Clones the latest source from GitHub
2. Rebuilds from source
3. Reinstalls the app and CLI

**Your flows, customizations, config, and results are never touched during updates.**

You can also update manually:

```bash
curl -fsSL https://raw.githubusercontent.com/ekeng92/aeon-dispatch/main/scripts/remote-install.sh | bash
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/ekeng92/aeon-dispatch/main/scripts/remote-install.sh | bash -s -- --uninstall
```

Or manually:

```bash
# Remove app and CLI
rm -rf ~/Applications/AEON\ Dispatch.app
rm -f ~/.local/bin/dispatch

# Remove LaunchAgent (if installed)
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.aeon.dispatch.plist 2>/dev/null
rm -f ~/Library/LaunchAgents/com.aeon.dispatch.plist

# Optionally remove user data
# rm -rf ~/.aeon-dispatch
```

## Building from Source

```bash
git clone https://github.com/ekeng92/aeon-dispatch.git
cd aeon-dispatch
make install
```

Other targets:

```bash
make build    # Compile only
make app      # Build .app bundle
make run      # Build and open
make clean    # Remove build artifacts
```

## Architecture

```
~/.aeon-dispatch/
  config.sh            # Copilot CLI path, model defaults
  flows/               # Flow JSON definitions
  customizations/      # Customization JSON profiles
  results/             # Dispatch output files
  logs/                # Execution logs
```

The app is a SwiftUI `MenuBarExtra` with a popover panel. It watches the flows, customizations, and results directories for filesystem changes and refreshes automatically. Dispatch execution shells out to the `dispatch` CLI script, which invokes `copilot` with the resolved agent, model, prompt, and working directory.

## License

MIT
