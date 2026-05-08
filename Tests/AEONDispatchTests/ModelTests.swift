import XCTest
@testable import AEONDispatch

/// Tests for pure model logic: Customization.subtitle, FlowEditModel/CustomizationEditModel
/// field mapping, isNew, and FlowEditModel schedule round-trips.
final class ModelTests: XCTestCase {

    // MARK: - Customization.subtitle

    func test_subtitle_defaultContext() {
        let cust = makeCustomization(agent: "default", model: nil, workdir: nil)
        XCTAssertEqual(cust.subtitle, "default context")
    }

    func test_subtitle_customAgentOnly() {
        let cust = makeCustomization(agent: "alpha-dev", model: nil, workdir: nil)
        XCTAssertEqual(cust.subtitle, "alpha-dev")
    }

    func test_subtitle_agentAndModel() {
        let cust = makeCustomization(agent: "alpha-dev", model: "gpt-4.1", workdir: nil)
        XCTAssertEqual(cust.subtitle, "alpha-dev · gpt-4.1")
    }

    func test_subtitle_allFields() {
        let cust = makeCustomization(agent: "alpha-dev", model: "gpt-4.1", workdir: "/Users/ekeng/IdeaProjects/api")
        // workdir shows only the last path component
        XCTAssertEqual(cust.subtitle, "alpha-dev · gpt-4.1 · api")
    }

    func test_subtitle_workdirOnlyShowsLastComponent() {
        let cust = makeCustomization(agent: "default", model: nil, workdir: "/Users/ekeng/IdeaProjects/my-project")
        XCTAssertEqual(cust.subtitle, "my-project")
    }

    func test_subtitle_emptyModelSkipped() {
        let cust = makeCustomization(agent: "alpha-dev", model: "", workdir: nil)
        // Empty model string should be treated as absent
        XCTAssertEqual(cust.subtitle, "alpha-dev")
    }

    func test_subtitle_homeDirTildeReplacement() {
        let home = NSHomeDirectory()
        let cust = makeCustomization(agent: "default", model: nil, workdir: "\(home)/IdeaProjects/repo")
        // After tilde replacement, last component is "repo"
        XCTAssertEqual(cust.subtitle, "repo")
    }

    // MARK: - CustomizationEditModel

    func test_customizationEditModel_isNew_whenInitedEmpty() {
        let model = CustomizationEditModel()
        XCTAssertTrue(model.isNew)
    }

    func test_customizationEditModel_isNew_falseWhenInitedFromExisting() {
        let cust = makeCustomization()
        let model = CustomizationEditModel(from: cust)
        XCTAssertFalse(model.isNew)
    }

    func test_customizationEditModel_fieldsMatchSource() {
        let cust = makeCustomization(
            agent: "alpha-dev",
            model: "claude-4",
            workdir: "~/IdeaProjects/api",
            promptFile: "~/prompts/reviewer.md",
            description: "PR reviewer"
        )
        let model = CustomizationEditModel(from: cust)
        XCTAssertEqual(model.originalFileName, "my-cust")
        XCTAssertEqual(model.fileName, "my-cust")
        XCTAssertEqual(model.name, "My Cust")
        XCTAssertEqual(model.description, "PR reviewer")
        XCTAssertEqual(model.agent, "alpha-dev")
        XCTAssertEqual(model.model, "claude-4")
        XCTAssertEqual(model.workdir, "~/IdeaProjects/api")
        XCTAssertEqual(model.promptFile, "~/prompts/reviewer.md")
    }

    func test_customizationEditModel_nilOptionalsMappedToEmptyString() {
        let cust = makeCustomization(model: nil, workdir: nil, promptFile: nil, description: nil)
        let model = CustomizationEditModel(from: cust)
        XCTAssertEqual(model.model, "")
        XCTAssertEqual(model.workdir, "")
        XCTAssertEqual(model.promptFile, "")
        XCTAssertEqual(model.description, "")
    }

    // MARK: - FlowEditModel

    func test_flowEditModel_isNew_whenInitedEmpty() {
        let model = FlowEditModel()
        XCTAssertTrue(model.isNew)
    }

    func test_flowEditModel_isNew_falseWhenInitedFromExisting() {
        let flow = makeFlow()
        let model = FlowEditModel(from: flow)
        XCTAssertFalse(model.isNew)
    }

    func test_flowEditModel_scheduleMapping_manual() {
        let flow = makeFlow(schedule: .manual)
        let model = FlowEditModel(from: flow)
        XCTAssertEqual(model.scheduleType, .manual)
    }

    func test_flowEditModel_scheduleMapping_interval() {
        let flow = makeFlow(schedule: .interval(every: "4h", days: ["Mon", "Fri"], activeHours: ["09:00", "17:00"]))
        let model = FlowEditModel(from: flow)
        XCTAssertEqual(model.scheduleType, .interval)
        XCTAssertEqual(model.scheduleEvery, "4h")
        XCTAssertEqual(model.scheduleDays, ["Mon", "Fri"])
        XCTAssertEqual(model.activeHoursStart, "09:00")
        XCTAssertEqual(model.activeHoursEnd, "17:00")
    }

    func test_flowEditModel_scheduleMapping_intervalNoDays() {
        let flow = makeFlow(schedule: .interval(every: "30m", days: nil, activeHours: nil))
        let model = FlowEditModel(from: flow)
        XCTAssertEqual(model.scheduleType, .interval)
        XCTAssertEqual(model.scheduleEvery, "30m")
        XCTAssertEqual(model.scheduleDays, [])
        XCTAssertEqual(model.activeHoursStart, "")
        XCTAssertEqual(model.activeHoursEnd, "")
    }

    func test_flowEditModel_scheduleMapping_timeOfDay() {
        let flow = makeFlow(schedule: .timeOfDay(at: "16:00", days: ["Mon", "Tue", "Wed", "Thu", "Fri"], activeHours: nil))
        let model = FlowEditModel(from: flow)
        XCTAssertEqual(model.scheduleType, .timeOfDay)
        XCTAssertEqual(model.scheduleAt, "16:00")
        XCTAssertEqual(model.scheduleDays.count, 5)
    }

    func test_flowEditModel_activeHours_requiresBothValuesToPopulate() {
        // If activeHours array has fewer than 2 items, start/end should stay empty
        let flow = makeFlow(schedule: .interval(every: "1h", days: nil, activeHours: ["09:00"]))
        let model = FlowEditModel(from: flow)
        XCTAssertEqual(model.activeHoursStart, "")
        XCTAssertEqual(model.activeHoursEnd, "")
    }

    func test_flowEditModel_customizationRef() {
        let flow = makeFlow(customization: "alpha-dev-cust")
        let model = FlowEditModel(from: flow)
        XCTAssertEqual(model.customizationRef, "alpha-dev-cust")
    }

    func test_flowEditModel_nilCustomizationMappedToEmptyString() {
        let flow = makeFlow(customization: nil)
        let model = FlowEditModel(from: flow)
        XCTAssertEqual(model.customizationRef, "")
    }

    // MARK: - FlowEditModel.commonIntervals / allDays / weekdays

    func test_commonIntervals_notEmpty() {
        XCTAssertFalse(FlowEditModel.commonIntervals.isEmpty)
    }

    func test_allDays_count() {
        XCTAssertEqual(FlowEditModel.allDays.count, 7)
    }

    func test_weekdays_count() {
        XCTAssertEqual(FlowEditModel.weekdays.count, 5)
        XCTAssertFalse(FlowEditModel.weekdays.contains("Sat"))
        XCTAssertFalse(FlowEditModel.weekdays.contains("Sun"))
    }

    // MARK: - Helpers

    private func makeCustomization(
        fileName: String = "my-cust",
        name: String = "My Cust",
        agent: String = "default",
        model: String? = nil,
        workdir: String? = nil,
        promptFile: String? = nil,
        description: String? = nil
    ) -> DispatchManager.Customization {
        DispatchManager.Customization(
            fileName: fileName, name: name, description: description,
            agent: agent, model: model, workdir: workdir, promptFile: promptFile
        )
    }

    private func makeFlow(
        fileName: String = "my-flow",
        name: String = "My Flow",
        customization: String? = nil,
        schedule: DispatchManager.ScheduleConfig = .manual
    ) -> DispatchManager.Flow {
        DispatchManager.Flow(
            fileName: fileName, name: name, customization: customization,
            prompt: "test prompt", promptFile: nil, preflight: nil,
            enabled: true, schedule: schedule,
            agent: "default", model: nil, workdir: nil
        )
    }
}
