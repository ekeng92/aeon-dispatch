# Feature Inventory — AEON Dispatch

> Generated: 2026-05-10
> Repo: aeon-dispatch
> Stack: Swift 5.9, SwiftUI, macOS 13+, zsh CLI

## Summary

| Layer | Feature Count |
|-------|--------------|
| Swift App (Menu Bar) | 8 |
| CLI (`dispatch`) | 7 |
| Install/Packaging | 3 |
| Configuration/Examples | 3 |
| **Total** | **21** |

---

## Swift App Features

### 1. App Entry & Menu Bar Shell
- **Files**: `AEONDispatchApp.swift`
- **Tests**: None
- **Status**: Core app lifecycle, NSPanel popover, click-outside-to-close, status bar icon, global/local event monitors

### 2. Content View (Main Popover UI)
- **Files**: `ContentView.swift`
- **Tests**: None (UI layer)
- **Status**: Status card, customizations list, flows list, recent results, quick actions, update section, activity log, quit button, import sheet

### 3. Dispatch Manager (Core Business Logic)
- **Files**: `DispatchManager.swift`
- **Tests**: `ModelTests.swift` (partial), `ScheduleConfigTests.swift`
- **Status**: Flow/Customization CRUD, flow execution via Process, result loading, file watching, dependency checking, state management, notifications, update checking, import scanning

### 4. Flow Editor View
- **Files**: `FlowEditorView.swift`
- **Tests**: None (UI layer)
- **Status**: Create/edit flows with identity, prompt (inline/file), execution context (customization ref or inline), preflight gate, schedule config, delete confirmation

### 5. Customization Editor View
- **Files**: `CustomizationEditorView.swift`
- **Tests**: None (UI layer)
- **Status**: Create/edit customizations with identity, execution context, prompt file, usage summary, delete confirmation

### 6. Formatting Utilities
- **Files**: `Formatting.swift`
- **Tests**: `FormattingTests.swift` (full coverage)
- **Status**: `relativeTimeString`, `formatISOTimestamp`, `slugify` — pure functions, well tested

### 7. Build Info
- **Files**: `BuildInfo.swift`
- **Tests**: None
- **Status**: Commit SHA placeholder stamped at build time by Makefile

### 8. Window Manager
- **Files**: `AEONDispatchApp.swift` (WindowManager class)
- **Tests**: None
- **Status**: Manages editor windows for flows/customizations, prevents duplicates, floating level

---

## CLI Features

### 9. Flow Execution (`dispatch run`)
- **Files**: `dispatch` (shell script)
- **Tests**: None
- **Status**: Foreground execution, Copilot CLI invocation, result capture to markdown, session ID extraction, state tracking, notifications

### 10. Batch Execution (`dispatch run-all`)
- **Files**: `dispatch`
- **Tests**: None
- **Status**: Iterates enabled flows, checks if due, executes in background

### 11. Schedule Engine
- **Files**: `dispatch`
- **Tests**: None (shell)
- **Status**: Interval and time-of-day parsing, day filters, active hours, last-run tracking via state.json

### 12. Flow/Results Management
- **Files**: `dispatch`
- **Tests**: None
- **Status**: `list`, `results`, `open`, `status` commands

### 13. LaunchAgent Scheduler
- **Files**: `dispatch`
- **Tests**: None
- **Status**: `install`/`uninstall` commands, generates plist, launchctl load/unload

### 14. Sync/Import
- **Files**: `dispatch` + `DispatchManager.swift`
- **Tests**: None
- **Status**: CLI `sync` copies flows/customizations/prompts from project folders. App UI import scans for SKILL.md, .instructions.md, .agent.md, .prompt.md, .chatmode.md files

### 15. Self-Update
- **Files**: `DispatchManager.swift`
- **Tests**: None
- **Status**: GitHub API SHA check, `curl | bash` remote-install for update

---

## Install/Packaging

### 16. Local Install Script
- **Files**: `scripts/install.sh`
- **Tests**: None
- **Status**: Full install pipeline: prerequisites check, build, app install, CLI install, LaunchAgent setup, example seeding

### 17. Remote Install Script
- **Files**: `scripts/remote-install.sh`
- **Tests**: None
- **Status**: One-liner curl-pipe-bash installer, clones repo, delegates to install.sh

### 18. Uninstall Script
- **Files**: `scripts/uninstall.sh`
- **Tests**: None
- **Status**: Cleanup of app, CLI, LaunchAgent. Preserves user data

---

## Configuration/Examples

### 19. Example Flows
- **Files**: `examples/*.json`
- **Tests**: None
- **Status**: 5 flows (git-standup, morning-planner, daily-reflection, pr-review, repo-health)

### 20. Example Customizations
- **Files**: `examples/customizations/default-copilot.json`
- **Tests**: None
- **Status**: Single default customization

### 21. Example Prompts
- **Files**: `examples/prompts/*.md`
- **Tests**: None
- **Status**: 3 prompt files (daily-reflection, morning-planner, repo-health)

---

## Cross-Cutting Observations

- **Test coverage is thin**: Only `Formatting.swift` and model types have tests. The core `DispatchManager` business logic (CRUD, execution, import) has no test coverage beyond model field mapping
- **No integration tests**: No test verifies the CLI script behavior
- **Dual implementation**: Schedule logic exists in both Swift (DispatchManager.ScheduleConfig) and shell (dispatch script). The Swift side only holds the model; the shell side does the actual scheduling
- **No `.github/` directory**: No CI, no instruction files, no repo-specific copilot instructions
- **Security surface**: Update mechanism uses `curl | bash` from GitHub raw URLs. Preflight gates execute arbitrary shell via `eval`. No auth on the GitHub API check
