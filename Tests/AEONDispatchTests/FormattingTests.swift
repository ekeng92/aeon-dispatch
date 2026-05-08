import XCTest
@testable import AEONDispatch

/// Tests for Formatting.swift utilities: relativeTimeString, formatISOTimestamp, slugify.
/// These functions are the only "pure logic" outside of AppKit, so they are the
/// primary unit-testable surface. Every branch is exercised here.
final class FormattingTests: XCTestCase {

    private let now = Date(timeIntervalSinceReferenceDate: 1_000_000)

    // MARK: - relativeTimeString

    func test_relativeTime_justNow_under60Seconds() {
        let date = now.addingTimeInterval(-30)
        XCTAssertEqual(relativeTimeString(from: date, relativeTo: now), "just now")
    }

    func test_relativeTime_justNow_zeroSeconds() {
        XCTAssertEqual(relativeTimeString(from: now, relativeTo: now), "just now")
    }

    func test_relativeTime_justNow_exactlyOneSecondBelowThreshold() {
        let date = now.addingTimeInterval(-59)
        XCTAssertEqual(relativeTimeString(from: date, relativeTo: now), "just now")
    }

    func test_relativeTime_minutes() {
        let date = now.addingTimeInterval(-5 * 60)
        XCTAssertEqual(relativeTimeString(from: date, relativeTo: now), "5m ago")
    }

    func test_relativeTime_minutes_59() {
        let date = now.addingTimeInterval(-59 * 60)
        XCTAssertEqual(relativeTimeString(from: date, relativeTo: now), "59m ago")
    }

    func test_relativeTime_hours() {
        let date = now.addingTimeInterval(-2 * 3600)
        XCTAssertEqual(relativeTimeString(from: date, relativeTo: now), "2h ago")
    }

    func test_relativeTime_hours_23() {
        let date = now.addingTimeInterval(-23 * 3600)
        XCTAssertEqual(relativeTimeString(from: date, relativeTo: now), "23h ago")
    }

    func test_relativeTime_days() {
        let date = now.addingTimeInterval(-3 * 86400)
        XCTAssertEqual(relativeTimeString(from: date, relativeTo: now), "3d ago")
    }

    func test_relativeTime_days_truncatesNotRounds() {
        // 1.9 days should show as "1d ago" (integer division, not rounding)
        let date = now.addingTimeInterval(-(1.9 * 86400))
        XCTAssertEqual(relativeTimeString(from: date, relativeTo: now), "1d ago")
    }

    // MARK: - formatISOTimestamp

    func test_formatISO_withFractionalSeconds() {
        // 5 minutes ago — ISO with fractional seconds
        let fiveMinsAgo = now.addingTimeInterval(-5 * 60)
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso = df.string(from: fiveMinsAgo)

        let result = formatISOTimestamp(iso, relativeTo: now)
        XCTAssertEqual(result, "5m ago")
    }

    func test_formatISO_withoutFractionalSeconds() {
        // 2 hours ago — ISO without fractional seconds
        let twoHoursAgo = now.addingTimeInterval(-2 * 3600)
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime]
        let iso = df.string(from: twoHoursAgo)

        let result = formatISOTimestamp(iso, relativeTo: now)
        XCTAssertEqual(result, "2h ago")
    }

    func test_formatISO_invalidStringReturnedAsIs() {
        let garbage = "not-a-date"
        let result = formatISOTimestamp(garbage, relativeTo: now)
        XCTAssertEqual(result, garbage)
    }

    func test_formatISO_emptyStringReturnedAsIs() {
        let result = formatISOTimestamp("", relativeTo: now)
        XCTAssertEqual(result, "")
    }

    // MARK: - slugify

    func test_slugify_lowercasesInput() {
        XCTAssertEqual(slugify("My Flow"), "my-flow")
    }

    func test_slugify_spacesToHyphens() {
        XCTAssertEqual(slugify("HI PR Reviewer"), "hi-pr-reviewer")
    }

    func test_slugify_stripsSpecialCharacters() {
        XCTAssertEqual(slugify("My Flow (v2)!"), "my-flow-v2")
    }

    func test_slugify_preservesExistingHyphens() {
        XCTAssertEqual(slugify("daily-reflection"), "daily-reflection")
    }

    func test_slugify_preservesNumbers() {
        XCTAssertEqual(slugify("PR Review v2"), "pr-review-v2")
    }

    func test_slugify_emptyString() {
        XCTAssertEqual(slugify(""), "")
    }

    func test_slugify_onlySpecialChars() {
        XCTAssertEqual(slugify("!@#$%"), "")
    }

    func test_slugify_multipleSpaces() {
        // Multiple spaces each become a hyphen
        XCTAssertEqual(slugify("a  b"), "a--b")
    }
}
