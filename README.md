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
# Run a flow interactively
dispatch run git-standup

# List all flows and their status
dispatch list

# Import flows/customizations/prompts from a project folder
dispatch sync ~/Projects/my-repo/.dispatch

# Show scheduler and system status
dispatch status

# View recent results
dispatch results
```

### Scheduling

The app can install a LaunchAgent that runs the dispatch scheduler every 5 minutes. Flows with a `schedule` field are executed automatically based on their cron expression. Enable/disable from the "Actions" section in the menu bar popover.

### Included Examples

The install seeds five example flows that show different dispatch patterns:

| Flow | Schedule | What It Does |
|------|----------|-------------|
| **Git Standup** | Manual | Summarizes recent git activity across repos. Run with `dispatch run git-standup` |
| **Morning Planner** | Daily 8:30 AM (weekdays) | Scans tasks, git status, and blockers to plan your day |
| **Daily Reflection** | Daily 4:00 PM (weekdays) | Reviews the day's commits and captures learnings |
| **PR Review** | Every 30m (work hours) | Checks for open PRs and posts reviews. Uses `preflight` to skip when no PRs exist |
| **Repo Health** | Monday 9:00 AM | Weekly dependency, test, and code quality check |

All scheduled flows start **disabled**. Enable the ones you want from the menu bar app or edit the JSON directly.

### Syncing from a Project Folder

Teams can share dispatch configurations through their repos. Place a `.dispatch/` folder (or any folder) with `flows/`, `customizations/`, and/or `prompts/` subdirectories, then run:

```bash
dispatch sync ~/Projects/my-repo/.dispatch
```

This copies the contents into `~/.aeon-dispatch/`, merging with your existing configuration.

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

### Running Tests

Tests require **Xcode** (not just CommandLineTools). With Xcode installed:

```bash
xcodebuild test -scheme AEONDispatch -destination "platform=macOS"
```

## Security Model

Flows and customizations are JSON files stored in `~/.aeon-dispatch/`. They are treated as **user-authored, trusted configuration**. Flows can specify preflight shell commands and prompts that execute with your user privileges.

**Do not import flows from untrusted sources.** The `dispatch sync` command copies files without sandboxing. Review any shared flow definitions before importing them, especially those with `preflight` commands.

Updates are fetched from this GitHub repository and compiled from source on your machine. The update mechanism does not verify cryptographic signatures.

## Architecture

```
~/.aeon-dispatch/
  config.sh            # Copilot CLI path, model defaults
  flows/               # Flow JSON definitions
  customizations/      # Customization JSON profiles
  prompts/             # Prompt files (.prompt.md)
  results/             # Dispatch output files
  logs/                # Execution logs
```

The app is a SwiftUI `MenuBarExtra` with a popover panel. It watches the flows, customizations, and results directories for filesystem changes and refreshes automatically. Dispatch execution shells out to the `dispatch` CLI script, which invokes `copilot` with the resolved agent, model, prompt, and working directory.

## License

MIT
