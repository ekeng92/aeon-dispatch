# Review Findings — AEON Dispatch

> Generated: 2026-05-10
> Auditor: AEON Prime (Claude Opus 4.6)
> Scope: Full codebase (7 Swift files, 1 shell script, 3 install scripts, examples, docs)

## Summary

| Severity | Count |
|----------|-------|
| 🔴 Critical | 2 |
| 🟠 High | 5 |
| 🟡 Medium | 8 |
| 🟢 Low | 6 |
| **Total** | **21** |

---

## 🔴 Critical

### C1. `eval` on preflight gate enables arbitrary code execution
- **File**: `dispatch` line ~248
- **Detail**: `eval "${preflight}"` executes arbitrary shell from JSON flow config. If a malicious flow JSON is synced from an untrusted source via `dispatch sync`, arbitrary code runs with user privileges
- **Risk**: RCE via crafted flow file
- **Fix**: Not easily fixable without breaking functionality. Document the security model: flows are user-authored config, treated as trusted. Add a warning in README and sync command

### C2. `curl | bash` update mechanism with no integrity verification
- **File**: `DispatchManager.swift` `runUpdate()`, `scripts/remote-install.sh`
- **Detail**: Update downloads and executes `remote-install.sh` via `curl -fsSL | bash` from GitHub raw URL. No checksum, no signature, no pinned commit. A compromised GitHub account or MITM could inject arbitrary code
- **Risk**: Supply chain attack via compromised update
- **Fix**: Pin the install to a specific tag/SHA, add checksum verification, or at minimum warn the user before executing

---

## 🟠 High

### H1. No test coverage for DispatchManager CRUD operations
- **File**: `DispatchManager.swift`
- **Detail**: `saveFlow()`, `deleteFlow()`, `saveCustomization()`, `deleteCustomization()` have zero tests. These write directly to the filesystem. A regression could silently corrupt or delete user data
- **Fix**: Extract file I/O behind a protocol, test CRUD logic against in-memory storage

### H2. No test coverage for flow execution logic
- **File**: `DispatchManager.swift` `runFlow()`
- **Detail**: The core feature, running a flow, has no tests. Process spawning, output capture, state updates, and notification delivery are all untested
- **Fix**: At minimum test the argument building logic. Extract Copilot CLI command construction into a testable pure function

### H3. No test coverage for import/scan logic
- **File**: `DispatchManager.swift` `scanImportCandidates()`, `importCandidates()`
- **Detail**: File type detection, human name generation, and slug deduplication are untested. These are pure-logic functions that could be tested without filesystem access
- **Fix**: Extract `importedType(for:)` and `humanName(for:type:)` as internal/public and test them

### H4. Shell script has no test coverage
- **File**: `dispatch`
- **Detail**: 700+ line shell script with schedule parsing, flow execution, state management, sync, and launchd management. Zero tests. The schedule engine (`is_flow_due`, `parse_interval`, `check_day_filter`, `check_active_hours`) is particularly risky
- **Fix**: Add shell tests (bats/shunit2) or port critical logic to Swift where it can be tested

### H5. `swift test` fails without full Xcode
- **File**: `Package.swift`, test setup
- **Detail**: `swift test` fails with `no such module 'XCTest'` on systems with only CommandLineTools. This means tests cannot run in a standard CI environment without Xcode. The README doesn't mention this requirement
- **Risk**: Tests appear to exist but are unrunnable on the development machine
- **Fix**: Document the Xcode requirement for testing, or investigate using swift-testing framework instead of XCTest

---

## 🟡 Medium

### M1. Duplicate schedule logic between Swift and shell
- **File**: `DispatchManager.swift` (ScheduleConfig), `dispatch` (is_flow_due, parse_interval)
- **Detail**: Schedule representation exists in both layers but serves different purposes. Swift decodes for display; shell evaluates for execution. Any schedule format change must be updated in both places
- **Fix**: Document the dual-representation clearly. Consider making the CLI the single source of truth for schedule evaluation

### M2. `runUpdate()` doesn't actually restart the app
- **File**: `DispatchManager.swift` `runUpdate()`
- **Detail**: After a successful update, it logs "Restart the app to use the new version" but doesn't offer a restart button or auto-restart. The old binary continues running until manually restarted
- **Fix**: Add `NSApp.terminate(nil)` after successful update, or use `Process` to relaunch

### M3. Error handling in loadFlows/loadCustomizations silently drops parse failures
- **File**: `DispatchManager.swift` `loadFlows()`, `loadCustomizations()`
- **Detail**: Parse failures are logged to the activity log but the corrupted file is silently skipped. User has no persistent indication that a flow/customization failed to load
- **Fix**: Show corrupted files in the UI with an error badge, or add a persistent error state

### M4. GitHub API rate limiting not handled
- **File**: `DispatchManager.swift` `checkForUpdate()`
- **Detail**: Unauthenticated GitHub API requests are limited to 60/hour. If the app checks frequently (e.g., every 30 minutes on the timer), rate limits could trigger. The error message would be generic "Could not parse response"
- **Fix**: Parse rate limit headers, cache results, reduce check frequency

### M5. `readCopilotPath()` uses string matching instead of proper config parsing
- **File**: `DispatchManager.swift` `readCopilotPath()`
- **Detail**: Reads `config.sh` by string-splitting lines on `DISPATCH_COPILOT=`. This is fragile: commented-out lines, lines with `export`, or values with `=` in them could break
- **Fix**: Use a proper shell-compatible parser or switch config to JSON/plist

### M6. `openTerminalForFlow` uses AppleScript injection
- **File**: `ContentView.swift` `openTerminalForFlow()`
- **Detail**: Flow name is interpolated directly into an AppleScript string: `"tell application \"Terminal\" to do script \"echo 'AEON Dispatch — \(flow.name)'; tail -f ..."`. A flow name containing single quotes or backslashes could break or inject AppleScript
- **Fix**: Sanitize `flow.name` before interpolation, or use Process/NSTask to open Terminal instead

### M7. File watchers don't debounce
- **File**: `DispatchManager.swift` `startFileWatchers()`
- **Detail**: `DispatchSource.makeFileSystemObjectSource` fires on every filesystem event. Saving a file can trigger multiple events rapidly, causing redundant reloads
- **Fix**: Add a debounce (e.g., 0.5s delay before reloading)

### M8. `slugify` produces double hyphens from multiple spaces
- **File**: `Formatting.swift`
- **Detail**: `slugify("a  b")` produces `"a--b"`. The test documents this behavior but it's ugly. Common slugify implementations collapse multiple hyphens
- **Fix**: Add `.replacingOccurrences(of: "--+", with: "-", options: .regularExpression)` after the space replacement

---

## 🟢 Low

### L1. No app icon bundled in repo
- **File**: `resources/`
- **Detail**: `Info.plist` references `AppIcon.icns` but the file isn't in the repo. The Makefile conditionally copies it (`test -f resources/AppIcon.icns && cp ...`). App runs without an icon in the Dock/Finder

### L2. README doesn't document test requirements
- **File**: `README.md`
- **Detail**: README lists prerequisites for running (macOS 13+, Swift, Git, Copilot CLI) but doesn't mention Xcode is needed for running tests

### L3. `DISPATCH_VERSION` hardcoded in CLI
- **File**: `dispatch` line 24
- **Detail**: Version is hardcoded as `0.1.0`. No mechanism to keep CLI version in sync with app version

### L4. `notify()` in CLI uses AppleScript fallback
- **File**: `dispatch` `notify()` function
- **Detail**: Uses `osascript -e "display notification ..."` which shows as "Script Editor" in Notification Center, not as "AEON Dispatch"

### L5. Product vision doc could be in README
- **File**: `docs/PRODUCT-VISION.md`
- **Detail**: Good content that could improve the README's "what and why" section

### L6. No CONTRIBUTING.md or CODE_OF_CONDUCT.md
- **File**: repo root
- **Detail**: Open source repo (MIT) with no contribution guidelines

---

## Cross-Cutting Issues

### Pattern: No input validation on JSON flow/customization files
Multiple features load JSON from `~/.aeon-dispatch/` without schema validation. Malformed or missing fields cause silent failures or crashes. Affects: `loadFlows()`, `loadCustomizations()`, CLI `execute_flow()`.

### Pattern: No error boundary in UI
The SwiftUI views have no error handling for display failures. A nil optional or unexpected state could crash the popover. SwiftUI's error propagation is implicit.

### Pattern: Logs go to /tmp
Debug logging writes to `/tmp/aeon-dispatch.log` which is world-readable on macOS. No sensitive data is logged currently, but the pattern is risky if credentials are ever involved.

---

## Test Suite Status

| Test File | Tests | Status |
|-----------|-------|--------|
| FormattingTests.swift | 14 | ⚠️ Cannot run (no Xcode) |
| ModelTests.swift | 18 | ⚠️ Cannot run (no Xcode) |
| ScheduleConfigTests.swift | 11 | ⚠️ Cannot run (no Xcode) |
| **Total** | **43** | **All blocked by missing Xcode** |

The tests themselves are well-written and cover the extractable pure logic thoroughly. The problem is they can't execute on this machine.
