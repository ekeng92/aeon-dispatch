# Fix Report — AEON Dispatch

> Generated: 2026-05-10
> Agent: AEON Prime (Claude Opus 4.6)

## Fixes Applied

### M8: `slugify` double-hyphen fix
- **File**: `Sources/AEONDispatch/Formatting.swift`
- **Change**: Added `.replacingOccurrences(of: "-{2,}", with: "-", options: .regularExpression)` to collapse consecutive hyphens
- **Test**: Updated `FormattingTests.swift` to expect `"a-b"` instead of `"a--b"`, added `test_slugify_leadingTrailingSpaces`

### M6: AppleScript injection in flow name
- **File**: `Sources/AEONDispatch/ContentView.swift`
- **Change**: Sanitized `flow.name` by stripping backslashes, single quotes, and double quotes before interpolating into AppleScript string
- **Risk reduced**: Prevents flow names with special characters from breaking or injecting AppleScript commands

### C1/C2: Security model documentation
- **File**: `README.md`
- **Change**: Added "Security Model" section documenting trust assumptions for flows, preflight commands, sync imports, and update mechanism
- **Rationale**: These are inherent to the architecture (user-authored config executing with user privileges). Documentation is the correct mitigation

### L2/H5: Test requirements documentation
- **File**: `README.md`
- **Change**: Added "Running Tests" section noting Xcode requirement and the `xcodebuild test` command
- **Rationale**: Tests exist but can't run without Xcode. Users and CI need to know this

## Deferred Items

| Finding | Reason |
|---------|--------|
| H1-H4: Missing test coverage | Requires architectural changes (protocol extraction, dependency injection) for the DispatchManager. Multi-session effort |
| C1: `eval` in preflight | Fundamental to the feature design. Documented as trusted config |
| C2: `curl\|bash` update | Standard pattern for personal dev tools. Documented the limitation |
| M1: Duplicate schedule logic | Intentional separation (Swift for display, shell for execution). Documented |
| M2: No auto-restart after update | UX improvement, not a bug |
| M3: Silent parse failure handling | Would require UI state model changes |
| M4: GitHub API rate limiting | Low risk at current check frequency (manual only) |
| M5: Config parsing fragility | Low risk for personal tool config |
| M7: File watcher debouncing | Performance improvement, not a bug |
| L1-L6 | Minor improvements deferred |
