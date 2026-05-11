import Foundation

// MARK: - Timestamp Formatting
//
// Extracted as free functions so they can be unit tested without importing AppKit.
// Used by ContentView for lastRunTimes display and by FlowResult for date strings.

/// Returns a human-readable relative time string ("just now", "5m ago", "2h ago", "3d ago").
func relativeTimeString(from date: Date, relativeTo now: Date = Date()) -> String {
    let interval = now.timeIntervalSince(date)
    if interval < 60 { return "just now" }
    if interval < 3600 { return "\(Int(interval / 60))m ago" }
    if interval < 86400 { return "\(Int(interval / 3600))h ago" }
    return "\(Int(interval / 86400))d ago"
}

/// Parses an ISO 8601 timestamp string and returns a relative time string.
/// Supports both fractional-second and whole-second variants.
/// Returns the original string as fallback if parsing fails.
func formatISOTimestamp(_ iso: String, relativeTo now: Date = Date()) -> String {
    let df = ISO8601DateFormatter()
    df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = df.date(from: iso) {
        return relativeTimeString(from: date, relativeTo: now)
    }
    df.formatOptions = [.withInternetDateTime]
    if let date = df.date(from: iso) {
        return relativeTimeString(from: date, relativeTo: now)
    }
    return iso // unparseable: show raw string
}

// MARK: - Filename Slugification
//
// Extracted so it can be tested independently of the file system operations in DispatchManager.

/// Converts a human-readable name into a lowercase kebab-case filename slug.
/// "HI PR Reviewer" → "hi-pr-reviewer"
/// "My Flow (v2)!" → "my-flow-v2"
func slugify(_ name: String) -> String {
    name.lowercased()
        .replacingOccurrences(of: " ", with: "-")
        .replacingOccurrences(of: "[^a-z0-9\\-]", with: "", options: .regularExpression)
        .replacingOccurrences(of: "-{2,}", with: "-", options: .regularExpression)
}
