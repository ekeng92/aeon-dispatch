import XCTest
@testable import AEONDispatch

/// Tests for ScheduleConfig Codable round-trips and displayString.
///
/// ScheduleConfig has three cases (manual, interval, timeOfDay) with an unusual
/// dual-representation — "manual" encodes as a JSON string, the other two as
/// objects. These tests verify all paths through the custom Codable implementation.
final class ScheduleConfigTests: XCTestCase {

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // MARK: - displayString

    func test_displayString_manual() {
        XCTAssertEqual(DispatchManager.ScheduleConfig.manual.displayString, "manual")
    }

    func test_displayString_interval() {
        let config = DispatchManager.ScheduleConfig.interval(every: "30m", days: nil, activeHours: nil)
        XCTAssertEqual(config.displayString, "every 30m")
    }

    func test_displayString_timeOfDay() {
        let config = DispatchManager.ScheduleConfig.timeOfDay(at: "16:00", days: nil, activeHours: nil)
        XCTAssertEqual(config.displayString, "daily 16:00")
    }

    // MARK: - Decoding: manual

    func test_decode_manualAsString() throws {
        let json = #""manual""#.data(using: .utf8)!
        let config = try decoder.decode(DispatchManager.ScheduleConfig.self, from: json)
        guard case .manual = config else { return XCTFail("Expected .manual, got \(config)") }
    }

    // MARK: - Decoding: interval

    func test_decode_intervalMinimal() throws {
        let json = #"{"every":"1h"}"#.data(using: .utf8)!
        let config = try decoder.decode(DispatchManager.ScheduleConfig.self, from: json)
        guard case .interval(let every, let days, let hours) = config else {
            return XCTFail("Expected .interval, got \(config)")
        }
        XCTAssertEqual(every, "1h")
        XCTAssertNil(days)
        XCTAssertNil(hours)
    }

    func test_decode_intervalWithDaysAndActiveHours() throws {
        let json = #"{"every":"30m","days":["Mon","Fri"],"active_hours":["09:00","18:00"]}"#.data(using: .utf8)!
        let config = try decoder.decode(DispatchManager.ScheduleConfig.self, from: json)
        guard case .interval(let every, let days, let hours) = config else {
            return XCTFail("Expected .interval, got \(config)")
        }
        XCTAssertEqual(every, "30m")
        XCTAssertEqual(days, ["Mon", "Fri"])
        XCTAssertEqual(hours, ["09:00", "18:00"])
    }

    // MARK: - Decoding: timeOfDay

    func test_decode_timeOfDayMinimal() throws {
        let json = #"{"at":"08:30"}"#.data(using: .utf8)!
        let config = try decoder.decode(DispatchManager.ScheduleConfig.self, from: json)
        guard case .timeOfDay(let at, let days, let hours) = config else {
            return XCTFail("Expected .timeOfDay, got \(config)")
        }
        XCTAssertEqual(at, "08:30")
        XCTAssertNil(days)
        XCTAssertNil(hours)
    }

    func test_decode_timeOfDayWithWeekdays() throws {
        let json = #"{"at":"16:00","days":["Mon","Tue","Wed","Thu","Fri"]}"#.data(using: .utf8)!
        let config = try decoder.decode(DispatchManager.ScheduleConfig.self, from: json)
        guard case .timeOfDay(let at, let days, _) = config else {
            return XCTFail("Expected .timeOfDay, got \(config)")
        }
        XCTAssertEqual(at, "16:00")
        XCTAssertEqual(days?.count, 5)
    }

    // MARK: - Decoding: empty object fallback

    func test_decode_emptyObjectFallsBackToManual() throws {
        // An object with neither "every" nor "at" should default to .manual
        let json = #"{"days":["Mon"]}"#.data(using: .utf8)!
        let config = try decoder.decode(DispatchManager.ScheduleConfig.self, from: json)
        guard case .manual = config else { return XCTFail("Expected .manual fallback, got \(config)") }
    }

    // MARK: - Encoding round-trips

    func test_roundtrip_manual() throws {
        let original = DispatchManager.ScheduleConfig.manual
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(DispatchManager.ScheduleConfig.self, from: data)
        guard case .manual = decoded else { return XCTFail("Round-trip failed for .manual") }
    }

    func test_roundtrip_interval() throws {
        let original = DispatchManager.ScheduleConfig.interval(every: "15m", days: ["Mon", "Wed"], activeHours: ["09:00", "17:00"])
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(DispatchManager.ScheduleConfig.self, from: data)
        guard case .interval(let every, let days, let hours) = decoded else {
            return XCTFail("Round-trip failed for .interval")
        }
        XCTAssertEqual(every, "15m")
        XCTAssertEqual(days, ["Mon", "Wed"])
        XCTAssertEqual(hours, ["09:00", "17:00"])
    }

    func test_roundtrip_timeOfDay() throws {
        let original = DispatchManager.ScheduleConfig.timeOfDay(at: "09:00", days: ["Sat", "Sun"], activeHours: nil)
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(DispatchManager.ScheduleConfig.self, from: data)
        guard case .timeOfDay(let at, let days, let hours) = decoded else {
            return XCTFail("Round-trip failed for .timeOfDay")
        }
        XCTAssertEqual(at, "09:00")
        XCTAssertEqual(days, ["Sat", "Sun"])
        XCTAssertNil(hours)
    }
}
