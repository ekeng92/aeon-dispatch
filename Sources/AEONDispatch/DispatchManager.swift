import Foundation
import AppKit
import UserNotifications

final class DispatchManager: ObservableObject {

    // MARK: - Types

    struct Customization: Identifiable, Codable, Hashable {
        var id: String { fileName }
        let fileName: String
        let name: String
        let description: String?
        let agent: String
        let model: String?
        let workdir: String?
        let promptFile: String?

        enum CodingKeys: String, CodingKey {
            case name, description, agent, model, workdir
            case promptFile = "prompt_file"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.fileName = ""
            self.name = try c.decode(String.self, forKey: .name)
            self.description = try c.decodeIfPresent(String.self, forKey: .description)
            self.agent = try c.decodeIfPresent(String.self, forKey: .agent) ?? "default"
            self.model = try c.decodeIfPresent(String.self, forKey: .model)
            self.workdir = try c.decodeIfPresent(String.self, forKey: .workdir)
            self.promptFile = try c.decodeIfPresent(String.self, forKey: .promptFile)
        }

        init(fileName: String, name: String, description: String?, agent: String,
             model: String?, workdir: String?, promptFile: String?) {
            self.fileName = fileName
            self.name = name
            self.description = description
            self.agent = agent
            self.model = model
            self.workdir = workdir
            self.promptFile = promptFile
        }

        func withFileName(_ name: String) -> Customization {
            Customization(fileName: name, name: self.name, description: description,
                          agent: agent, model: model, workdir: workdir, promptFile: promptFile)
        }

        /// Summary line for display in pickers and lists
        var subtitle: String {
            var parts: [String] = []
            if agent != "default" { parts.append(agent) }
            if let m = model, !m.isEmpty { parts.append(m) }
            if let w = workdir, !w.isEmpty {
                let short = w.replacingOccurrences(of: NSHomeDirectory(), with: "~")
                    .split(separator: "/").last.map(String.init) ?? w
                parts.append(short)
            }
            return parts.isEmpty ? "default context" : parts.joined(separator: " · ")
        }
    }

    struct Flow: Identifiable, Codable {
        var id: String { fileName }
        let fileName: String
        let name: String
        let customization: String?
        let prompt: String?
        let promptFile: String?
        let preflight: String?
        let enabled: Bool
        let schedule: ScheduleConfig
        // Legacy inline fields (used when no customization is set)
        let agent: String?
        let model: String?
        let workdir: String?

        enum CodingKeys: String, CodingKey {
            case name, customization, prompt, preflight, enabled, schedule
            case agent, model, workdir
            case promptFile = "prompt_file"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.fileName = ""
            self.name = try c.decode(String.self, forKey: .name)
            self.customization = try c.decodeIfPresent(String.self, forKey: .customization)
            self.prompt = try c.decodeIfPresent(String.self, forKey: .prompt)
            self.promptFile = try c.decodeIfPresent(String.self, forKey: .promptFile)
            self.preflight = try c.decodeIfPresent(String.self, forKey: .preflight)
            self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
            self.schedule = try c.decode(ScheduleConfig.self, forKey: .schedule)
            self.agent = try c.decodeIfPresent(String.self, forKey: .agent)
            self.model = try c.decodeIfPresent(String.self, forKey: .model)
            self.workdir = try c.decodeIfPresent(String.self, forKey: .workdir)
        }

        init(fileName: String, name: String, customization: String?, prompt: String?,
             promptFile: String?, preflight: String?, enabled: Bool, schedule: ScheduleConfig,
             agent: String?, model: String?, workdir: String?) {
            self.fileName = fileName
            self.name = name
            self.customization = customization
            self.prompt = prompt
            self.promptFile = promptFile
            self.preflight = preflight
            self.enabled = enabled
            self.schedule = schedule
            self.agent = agent
            self.model = model
            self.workdir = workdir
        }

        func withFileName(_ name: String) -> Flow {
            Flow(fileName: name, name: self.name, customization: customization,
                 prompt: prompt, promptFile: promptFile, preflight: preflight,
                 enabled: enabled, schedule: schedule, agent: agent, model: model, workdir: workdir)
        }
    }

    enum ScheduleConfig: Codable {
        case manual
        case interval(every: String, days: [String]?, activeHours: [String]?)
        case timeOfDay(at: String, days: [String]?, activeHours: [String]?)

        var displayString: String {
            switch self {
            case .manual: return "manual"
            case .interval(let every, _, _): return "every \(every)"
            case .timeOfDay(let at, _, _): return "daily \(at)"
            }
        }

        init(from decoder: Decoder) throws {
            // Try as string first ("manual")
            if let _ = try? decoder.singleValueContainer().decode(String.self) {
                self = .manual
                return
            }
            // Otherwise it's an object
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let days = try c.decodeIfPresent([String].self, forKey: .days)
            let activeHours = try c.decodeIfPresent([String].self, forKey: .activeHours)

            if let every = try c.decodeIfPresent(String.self, forKey: .every) {
                self = .interval(every: every, days: days, activeHours: activeHours)
            } else if let at = try c.decodeIfPresent(String.self, forKey: .at) {
                self = .timeOfDay(at: at, days: days, activeHours: activeHours)
            } else {
                self = .manual
            }
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .manual:
                var sc = encoder.singleValueContainer()
                try sc.encode("manual")
            case .interval(let every, let days, let hours):
                try c.encode(every, forKey: .every)
                try c.encodeIfPresent(days, forKey: .days)
                try c.encodeIfPresent(hours, forKey: .activeHours)
            case .timeOfDay(let at, let days, let hours):
                try c.encode(at, forKey: .at)
                try c.encodeIfPresent(days, forKey: .days)
                try c.encodeIfPresent(hours, forKey: .activeHours)
            }
        }

        enum CodingKeys: String, CodingKey {
            case every, at, days
            case activeHours = "active_hours"
        }
    }

    struct FlowResult: Identifiable {
        let id = UUID()
        let flowId: String
        let timestamp: Date
        let filePath: String

        var timeString: String {
            Self.formatter.string(from: timestamp)
        }

        var dateString: String {
            Self.dateFormatter.string(from: timestamp)
        }

        private static let formatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f
        }()

        private static let dateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "MMM d, HH:mm"
            return f
        }()
    }

    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String

        var timeString: String {
            Self.formatter.string(from: timestamp)
        }

        private static let formatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "HH:mm:ss"
            return f
        }()
    }

    // MARK: - Published State

    @Published private(set) var customizations: [Customization] = []
    @Published private(set) var flows: [Flow] = []
    @Published private(set) var recentResults: [FlowResult] = []
    @Published private(set) var recentResultCount = 0
    @Published private(set) var activityLog: [LogEntry] = []
    @Published private(set) var schedulerRunning = false
    @Published private(set) var dispatchBinAvailable = false
    @Published private(set) var copilotAvailable = false
    @Published private(set) var runningFlows: Set<String> = []
    @Published private(set) var lastRunTimes: [String: String] = [:]
    @Published private(set) var updateState: UpdateState = .idle
    @Published private(set) var latestRemoteSHA: String?

    enum UpdateState: Equatable {
        case idle
        case checking
        case updateAvailable(String)
        case upToDate
        case updating
        case failed(String)
    }

    var buildCommit: String { BuildInfo.commitSHA }

    // MARK: - Paths

    private let home = NSHomeDirectory()
    private var dispatchHome: String { "\(home)/.aeon-dispatch" }
    private var customizationsDir: String { "\(dispatchHome)/customizations" }
    private var flowsDir: String { "\(dispatchHome)/flows" }
    private var resultsDir: String { "\(dispatchHome)/results" }
    private var stateFile: String { "\(dispatchHome)/state.json" }
    private var configFile: String { "\(dispatchHome)/config.sh" }
    private var dispatchBin: String { "\(home)/.local/bin/dispatch" }

    private let launchdLabel = "com.aeon.dispatch"
    private var launchdPlist: String {
        "\(home)/Library/LaunchAgents/\(launchdLabel).plist"
    }

    // MARK: - Private

    private var flowsDirDescriptor: Int32 = -1
    private var flowsDirSource: DispatchSourceFileSystemObject?
    private var customizationsDirDescriptor: Int32 = -1
    private var customizationsDirSource: DispatchSourceFileSystemObject?
    private var resultsDirDescriptor: Int32 = -1
    private var resultsDirSource: DispatchSourceFileSystemObject?
    private var refreshTimer: Timer?

    // MARK: - Init / Deinit

    init() {
        ensureDirectories()
        loadCustomizations()
        loadFlows()
        loadState()
        loadRecentResults()
        checkDependencies()
        checkScheduler()
        addLog("AEON Dispatch started")

        startFileWatchers()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        if let source = flowsDirSource {
            source.cancel()
        } else if flowsDirDescriptor >= 0 {
            close(flowsDirDescriptor)
        }
        if let source = customizationsDirSource {
            source.cancel()
        } else if customizationsDirDescriptor >= 0 {
            close(customizationsDirDescriptor)
        }
        if let source = resultsDirSource {
            source.cancel()
        } else if resultsDirDescriptor >= 0 {
            close(resultsDirDescriptor)
        }
        refreshTimer?.invalidate()
    }

    // MARK: - Public Actions

    func refresh() {
        loadCustomizations()
        loadFlows()
        loadState()
        loadRecentResults()
        checkDependencies()
        checkScheduler()
    }

    /// Path to the live output log for a running flow. Remains until next run.
    func flowLogPath(for fileName: String) -> String {
        "/tmp/aeon-dispatch-\(fileName).log"
    }

    func runFlow(_ flow: Flow) {
        guard !runningFlows.contains(flow.fileName) else {
            addLog("Already running: \(flow.name)")
            return
        }

        runningFlows.insert(flow.fileName)
        addLog("Starting: \(flow.name)")

        let logPath = flowLogPath(for: flow.fileName)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let task = Process()
            let pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            task.arguments = ["-l", "-c", "\(self.dispatchBin) run \(flow.fileName)"]
            task.standardOutput = pipe
            task.standardError = pipe

            // Write all output to a per-flow log so the user can tail it live
            FileManager.default.createFile(atPath: logPath, contents: nil)
            let logHandle = FileHandle(forWritingAtPath: logPath)
            let header = "=== \(flow.name) — started \(Date()) ===\n"
            logHandle?.write(header.data(using: .utf8) ?? Data())

            // Stream output to log in real time
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let chunk = handle.availableData
                guard !chunk.isEmpty else { return }
                logHandle?.write(chunk)
            }

            do {
                try task.run()
                task.waitUntilExit()

                pipe.fileHandleForReading.readabilityHandler = nil
                let footer = "\n=== exit \(task.terminationStatus) ===\n"
                logHandle?.write(footer.data(using: .utf8) ?? Data())
                logHandle?.closeFile()

                let success = task.terminationStatus == 0
                // Read the captured output for the failure detail line
                let output = (try? String(contentsOfFile: logPath, encoding: .utf8)) ?? ""
                let lastLines = output.split(separator: "\n").suffix(5).joined(separator: " ")

                DispatchQueue.main.async {
                    self.runningFlows.remove(flow.fileName)
                    if success {
                        self.addLog("Done: \(flow.name)")
                    } else {
                        let detail = lastLines.isEmpty ? "" : " — \(lastLines.prefix(200))"
                        self.addLog("Failed: \(flow.name) (exit \(task.terminationStatus))\(detail)")
                    }
                    self.refresh()
                    // Find the result file that was just created
                    let latestResult = self.recentResults.first(where: { $0.flowId == flow.fileName.replacingOccurrences(of: ".json", with: "") })
                    self.sendNotification(
                        title: success ? "Flow Complete" : "Flow Failed",
                        message: flow.name,
                        resultFilePath: latestResult?.filePath
                    )
                }
            } catch {
                pipe.fileHandleForReading.readabilityHandler = nil
                logHandle?.closeFile()
                DispatchQueue.main.async {
                    self.runningFlows.remove(flow.fileName)
                    self.addLog("Error: \(flow.name) - \(error.localizedDescription)")
                }
            }
        }
    }

    func openResult(_ result: FlowResult) {
        NSWorkspace.shared.open(URL(fileURLWithPath: result.filePath))
    }

    func openLatestResult(for flowId: String) {
        if let result = recentResults.first(where: { $0.flowId == flowId }) {
            openResult(result)
        }
    }

    func copyResultToClipboard(_ result: FlowResult) {
        if let content = try? String(contentsOfFile: result.filePath, encoding: .utf8) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
            addLog("Copied: \(result.flowId) result")
        }
    }

    func openFlowsFolder() {
        NSWorkspace.shared.open(URL(fileURLWithPath: flowsDir))
    }

    func openResultsFolder() {
        NSWorkspace.shared.open(URL(fileURLWithPath: resultsDir))
    }

    func installScheduler() {
        runDispatchCommand("install") { [weak self] success in
            self?.checkScheduler()
            self?.addLog(success ? "Scheduler installed" : "Scheduler install failed")
        }
    }

    func uninstallScheduler() {
        runDispatchCommand("uninstall") { [weak self] success in
            self?.checkScheduler()
            self?.addLog(success ? "Scheduler removed" : "Scheduler removal failed")
        }
    }

    // MARK: - Customization CRUD

    func saveCustomization(_ edit: CustomizationEditModel) {
        let fileName = edit.fileName.isEmpty ? slugify(edit.name) : edit.fileName

        var dict: [String: Any] = [
            "name": edit.name,
            "agent": edit.agent.isEmpty ? "default" : edit.agent,
        ]
        if !edit.description.isEmpty { dict["description"] = edit.description }
        if !edit.model.isEmpty { dict["model"] = edit.model }
        if !edit.workdir.isEmpty { dict["workdir"] = edit.workdir }
        if !edit.promptFile.isEmpty { dict["prompt_file"] = edit.promptFile }

        let path = "\(customizationsDir)/\(fileName).json"
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL(fileURLWithPath: path))
            if !edit.originalFileName.isEmpty && edit.originalFileName != fileName {
                let oldPath = "\(customizationsDir)/\(edit.originalFileName).json"
                try? FileManager.default.removeItem(atPath: oldPath)
            }
            addLog("Saved customization: \(edit.name)")
            loadCustomizations()
        }
    }

    func deleteCustomization(_ cust: Customization) {
        let path = "\(customizationsDir)/\(cust.fileName).json"
        try? FileManager.default.removeItem(atPath: path)
        addLog("Deleted customization: \(cust.name)")
        loadCustomizations()
    }

    // MARK: - Import from Directory

    /// File patterns that Aeon Dispatch treats as importable customization sources.
    static let importablePatterns: [String] = [
        "SKILL.md",
        ".instructions.md",
        ".agent.md",
        ".prompt.md",
        ".chatmode.md",
    ]

    /// Represents a file found during a directory scan, ready to preview before import.
    struct ImportCandidate: Identifiable {
        let id = UUID()
        let name: String        // Human-readable display name
        let fileName: String    // Slug used as the JSON file name
        let promptFile: String  // Absolute path to the source file
        let fileType: String    // "skill", "instruction", "agent", "prompt", "chatmode"
        var selected: Bool = true
    }

    /// Scan `directory` and return candidate customizations. Does NOT write anything yet.
    func scanImportCandidates(in directory: URL) -> [ImportCandidate] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var candidates: [ImportCandidate] = []
        let existingFileNames = Set(customizations.map(\.fileName))

        for case let fileURL as URL in enumerator {
            let name = fileURL.lastPathComponent
            guard let type = importedType(for: name) else { continue }

            // Derive a human name from the folder or file name
            let humanName = humanName(for: fileURL, type: type)
            let slug = slugify(humanName)

            // Skip if already imported
            if existingFileNames.contains(slug) { continue }

            candidates.append(ImportCandidate(
                name: humanName,
                fileName: slug,
                promptFile: fileURL.path,
                fileType: type
            ))
        }

        // Sort: skills first, then instructions, then others; alpha within group
        return candidates.sorted {
            if $0.fileType != $1.fileType { return $0.fileType < $1.fileType }
            return $0.name < $1.name
        }
    }

    /// Write the selected candidates to `~/.aeon-dispatch/customizations/`.
    /// Returns the count of successfully written files.
    @discardableResult
    func importCandidates(_ candidates: [ImportCandidate]) -> Int {
        var count = 0
        for candidate in candidates where candidate.selected {
            let dict: [String: Any] = [
                "name": candidate.name,
                "agent": "default",
                "description": "Imported \(candidate.fileType) from \(URL(fileURLWithPath: candidate.promptFile).deletingLastPathComponent().lastPathComponent)",
                "prompt_file": candidate.promptFile,
            ]
            let path = "\(customizationsDir)/\(candidate.fileName).json"
            if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]) {
                try? data.write(to: URL(fileURLWithPath: path))
                count += 1
            }
        }
        if count > 0 {
            addLog("Imported \(count) customization(s)")
            loadCustomizations()
        }
        return count
    }

    // MARK: - Import Helpers

    private func importedType(for fileName: String) -> String? {
        if fileName == "SKILL.md" { return "skill" }
        if fileName.hasSuffix(".instructions.md") { return "instruction" }
        if fileName.hasSuffix(".agent.md") { return "agent" }
        if fileName.hasSuffix(".prompt.md") { return "prompt" }
        if fileName.hasSuffix(".chatmode.md") { return "chatmode" }
        return nil
    }

    private func humanName(for url: URL, type: String) -> String {
        let fileName = url.lastPathComponent
        if fileName == "SKILL.md" {
            // Use the parent folder name: skills/my-cool-skill/SKILL.md → "my-cool-skill"
            let parent = url.deletingLastPathComponent().lastPathComponent
            return parent
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
        }
        // For .instructions.md etc, strip the suffix
        let base = fileName
            .replacingOccurrences(of: ".instructions.md", with: "")
            .replacingOccurrences(of: ".agent.md", with: "")
            .replacingOccurrences(of: ".prompt.md", with: "")
            .replacingOccurrences(of: ".chatmode.md", with: "")
        return base
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    func customizationEditModel(for cust: Customization) -> CustomizationEditModel {
        CustomizationEditModel(from: cust)
    }

    func newCustomizationEditModel() -> CustomizationEditModel {
        CustomizationEditModel()
    }

    /// Look up a customization by fileName
    func customization(named fileName: String) -> Customization? {
        customizations.first { $0.fileName == fileName }
    }

    /// Resolve the effective agent for a flow (customization > flow inline > default)
    func resolvedAgent(for flow: Flow) -> String {
        if let custName = flow.customization, let cust = customization(named: custName) {
            return cust.agent
        }
        return flow.agent ?? "default"
    }

    // MARK: - Flow CRUD

    func saveFlow(_ edit: FlowEditModel) {
        let fileName = edit.fileName.isEmpty ? slugify(edit.name) : edit.fileName

        var scheduleDict: Any
        switch edit.scheduleType {
        case .manual:
            scheduleDict = "manual"
        case .interval:
            var d: [String: Any] = ["every": edit.scheduleEvery]
            if !edit.scheduleDays.isEmpty { d["days"] = edit.scheduleDays }
            if !edit.activeHoursStart.isEmpty && !edit.activeHoursEnd.isEmpty {
                d["active_hours"] = [edit.activeHoursStart, edit.activeHoursEnd]
            }
            scheduleDict = d
        case .timeOfDay:
            var d: [String: Any] = ["at": edit.scheduleAt]
            if !edit.scheduleDays.isEmpty { d["days"] = edit.scheduleDays }
            if !edit.activeHoursStart.isEmpty && !edit.activeHoursEnd.isEmpty {
                d["active_hours"] = [edit.activeHoursStart, edit.activeHoursEnd]
            }
            scheduleDict = d
        }

        var dict: [String: Any] = [
            "name": edit.name,
            "schedule": scheduleDict,
            "enabled": edit.enabled,
        ]
        // Customization reference (preferred) or legacy inline fields
        if !edit.customizationRef.isEmpty {
            dict["customization"] = edit.customizationRef
        } else {
            if !edit.agent.isEmpty { dict["agent"] = edit.agent }
            if !edit.model.isEmpty { dict["model"] = edit.model }
            if !edit.workdir.isEmpty { dict["workdir"] = edit.workdir }
        }
        if !edit.prompt.isEmpty { dict["prompt"] = edit.prompt }
        if !edit.promptFile.isEmpty { dict["prompt_file"] = edit.promptFile }
        if !edit.preflight.isEmpty { dict["preflight"] = edit.preflight }

        let path = "\(flowsDir)/\(fileName).json"
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL(fileURLWithPath: path))
            if !edit.originalFileName.isEmpty && edit.originalFileName != fileName {
                let oldPath = "\(flowsDir)/\(edit.originalFileName).json"
                try? FileManager.default.removeItem(atPath: oldPath)
            }
            addLog("Saved: \(edit.name)")
            loadFlows()
        }
    }

    func deleteFlow(_ flow: Flow) {
        let path = "\(flowsDir)/\(flow.fileName).json"
        try? FileManager.default.removeItem(atPath: path)
        addLog("Deleted: \(flow.name)")
        loadFlows()
    }

    func editModel(for flow: Flow) -> FlowEditModel {
        FlowEditModel(from: flow)
    }

    func newFlowEditModel() -> FlowEditModel {
        FlowEditModel()
    }

    // MARK: - Update

    private static let githubAPIURL = "https://api.github.com/repos/ekeng92/aeon-dispatch/commits/main"
    private static let remoteInstallURL = "https://raw.githubusercontent.com/ekeng92/aeon-dispatch/main/scripts/remote-install.sh"

    func checkForUpdate() {
        updateState = .checking
        addLog("Checking for updates...")

        guard let url = URL(string: Self.githubAPIURL) else {
            updateState = .failed("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.updateState = .failed(error.localizedDescription)
                    self.addLog("Update check failed: \(error.localizedDescription)")
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let sha = json["sha"] as? String else {
                    self.updateState = .failed("Could not parse response")
                    self.addLog("Update check failed: bad response")
                    return
                }

                let remoteSHA = String(sha.prefix(7))
                self.latestRemoteSHA = remoteSHA

                if self.buildCommit == "dev" {
                    self.updateState = .updateAvailable(remoteSHA)
                    self.addLog("Dev build, latest: \(remoteSHA)")
                } else if remoteSHA == self.buildCommit {
                    self.updateState = .upToDate
                    self.addLog("Up to date (\(remoteSHA))")
                } else {
                    self.updateState = .updateAvailable(remoteSHA)
                    self.addLog("Update available: \(remoteSHA)")
                }
            }
        }.resume()
    }

    func runUpdate() {
        updateState = .updating
        addLog("Downloading and installing update...")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = [
                "-c",
                "curl -fsSL '\(Self.remoteInstallURL)' | bash -s -- --non-interactive"
            ]
            task.standardOutput = FileHandle.nullDevice
            task.standardError = FileHandle.nullDevice

            do {
                try task.run()
                task.waitUntilExit()
                let status = task.terminationStatus

                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if status == 0 {
                        self.addLog("Update installed. Restart the app to use the new version.")
                        self.updateState = .upToDate
                    } else {
                        self.updateState = .failed("Install exited with code \(status)")
                        self.addLog("Update failed (exit \(status))")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.updateState = .failed(error.localizedDescription)
                    self?.addLog("Update failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Private: Loading

    private func ensureDirectories() {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: customizationsDir, withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: flowsDir, withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: resultsDir, withIntermediateDirectories: true)
    }

    private func loadCustomizations() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: customizationsDir) else {
            customizations = []
            return
        }
        let decoder = JSONDecoder()
        var loaded: [Customization] = []
        for file in files.sorted() where file.hasSuffix(".json") {
            let path = "\(customizationsDir)/\(file)"
            guard let data = fm.contents(atPath: path) else { continue }
            do {
                var cust = try decoder.decode(Customization.self, from: data)
                let name = String(file.dropLast(5))
                cust = cust.withFileName(name)
                loaded.append(cust)
            } catch {
                addLog("Warning: could not parse customization '\(file)': \(error.localizedDescription)")
            }
        }
        customizations = loaded
    }

    private func loadFlows() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: flowsDir) else {
            flows = []
            return
        }

        let decoder = JSONDecoder()
        var loaded: [Flow] = []

        for file in files.sorted() where file.hasSuffix(".json") {
            let path = "\(flowsDir)/\(file)"
            guard let data = fm.contents(atPath: path) else { continue }
            do {
                var flow = try decoder.decode(Flow.self, from: data)
                let name = String(file.dropLast(5)) // remove .json
                flow = flow.withFileName(name)
                loaded.append(flow)
            } catch {
                addLog("Warning: could not parse flow '\(file)': \(error.localizedDescription)")
            }
        }

        flows = loaded
    }

    private func loadState() {
        guard let data = FileManager.default.contents(atPath: stateFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            lastRunTimes = [:]
            return
        }

        var times: [String: String] = [:]
        for (key, value) in json {
            if let obj = value as? [String: Any], let ts = obj["lastRun"] as? String {
                times[key] = ts
            }
        }
        lastRunTimes = times
    }

    private func loadRecentResults() {
        let fm = FileManager.default
        guard let flowDirs = try? fm.contentsOfDirectory(atPath: resultsDir) else {
            recentResults = []
            recentResultCount = 0
            return
        }

        var results: [FlowResult] = []
        let cutoff = Date().addingTimeInterval(-7 * 24 * 3600) // 7 days

        for dir in flowDirs {
            let dirPath = "\(resultsDir)/\(dir)"
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: dirPath, isDirectory: &isDir), isDir.boolValue else { continue }
            guard let files = try? fm.contentsOfDirectory(atPath: dirPath) else { continue }

            for file in files where file.hasSuffix(".md") {
                let filePath = "\(dirPath)/\(file)"
                guard let attrs = try? fm.attributesOfItem(atPath: filePath),
                      let modDate = attrs[.modificationDate] as? Date,
                      modDate > cutoff else { continue }

                results.append(FlowResult(
                    flowId: dir,
                    timestamp: modDate,
                    filePath: filePath
                ))
            }
        }

        results.sort { $0.timestamp > $1.timestamp }
        recentResults = Array(results.prefix(20))
        recentResultCount = results.filter {
            $0.timestamp > Date().addingTimeInterval(-24 * 3600)
        }.count
    }

    // MARK: - Private: Dependencies & Status

    private func checkDependencies() {
        dispatchBinAvailable = FileManager.default.isExecutableFile(atPath: dispatchBin)

        // Check copilot from config or default paths
        let copilotPath = readCopilotPath()
        copilotAvailable = FileManager.default.isExecutableFile(atPath: copilotPath)
    }

    private func checkScheduler() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments = ["list", launchdLabel]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
            schedulerRunning = task.terminationStatus == 0
        } catch {
            schedulerRunning = false
        }
    }

    private func readCopilotPath() -> String {
        // Try to read from config.sh
        guard let content = try? String(contentsOfFile: configFile, encoding: .utf8) else {
            return "/usr/local/bin/copilot"
        }
        for line in content.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("DISPATCH_COPILOT=") {
                let value = trimmed.dropFirst("DISPATCH_COPILOT=".count)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                if !value.isEmpty { return value }
            }
        }
        return "/usr/local/bin/copilot"
    }

    // MARK: - Private: File Watching

    private func startFileWatchers() {
        // Watch customizations directory
        customizationsDirDescriptor = Darwin.open(customizationsDir, O_EVTONLY)
        if customizationsDirDescriptor >= 0 {
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: customizationsDirDescriptor,
                eventMask: [.write, .rename, .delete],
                queue: .main
            )
            source.setEventHandler { [weak self] in self?.loadCustomizations() }
            source.setCancelHandler { [weak self] in
                if let fd = self?.customizationsDirDescriptor, fd >= 0 { close(fd) }
            }
            source.resume()
            customizationsDirSource = source
        }

        // Watch flows directory
        flowsDirDescriptor = Darwin.open(flowsDir, O_EVTONLY)
        if flowsDirDescriptor >= 0 {
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: flowsDirDescriptor,
                eventMask: [.write, .rename, .delete],
                queue: .main
            )
            source.setEventHandler { [weak self] in
                self?.loadFlows()
                self?.loadState()
            }
            source.setCancelHandler { [weak self] in
                if let fd = self?.flowsDirDescriptor, fd >= 0 {
                    close(fd)
                }
            }
            source.resume()
            flowsDirSource = source
        }

        // Watch results directory
        resultsDirDescriptor = Darwin.open(resultsDir, O_EVTONLY)
        if resultsDirDescriptor >= 0 {
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: resultsDirDescriptor,
                eventMask: [.write, .rename],
                queue: .main
            )
            source.setEventHandler { [weak self] in
                self?.loadRecentResults()
            }
            source.setCancelHandler { [weak self] in
                if let fd = self?.resultsDirDescriptor, fd >= 0 {
                    close(fd)
                }
            }
            source.resume()
            resultsDirSource = source
        }
    }

    // MARK: - Private: Helpers

    private func runDispatchCommand(_ command: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            task.arguments = ["-l", "-c", "\(self.dispatchBin) \(command)"]
            task.standardOutput = FileHandle.nullDevice
            task.standardError = FileHandle.nullDevice
            do {
                try task.run()
                task.waitUntilExit()
                DispatchQueue.main.async { completion(task.terminationStatus == 0) }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    private func addLog(_ message: String) {
        let entry = LogEntry(timestamp: Date(), message: message)
        activityLog.insert(entry, at: 0)
        if activityLog.count > 20 {
            activityLog = Array(activityLog.prefix(20))
        }
    }

    private func sendNotification(title: String, message: String, resultFilePath: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        if let path = resultFilePath {
            content.userInfo = ["resultFilePath": path]
        }
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                log("Notification error: \(error)", category: "DispatchManager")
            }
        }
    }
}

// MARK: - Customization Edit Model

final class CustomizationEditModel: ObservableObject {
    @Published var originalFileName: String = ""
    @Published var fileName: String = ""
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var agent: String = "default"
    @Published var model: String = ""
    @Published var workdir: String = ""
    @Published var promptFile: String = ""

    var isNew: Bool { originalFileName.isEmpty }

    init() {}

    init(from cust: DispatchManager.Customization) {
        self.originalFileName = cust.fileName
        self.fileName = cust.fileName
        self.name = cust.name
        self.description = cust.description ?? ""
        self.agent = cust.agent
        self.model = cust.model ?? ""
        self.workdir = cust.workdir ?? ""
        self.promptFile = cust.promptFile ?? ""
    }
}

// MARK: - Flow Edit Model

enum ScheduleType: String, CaseIterable {
    case manual = "Manual"
    case interval = "Interval"
    case timeOfDay = "Time of Day"
}

final class FlowEditModel: ObservableObject {
    @Published var originalFileName: String = ""
    @Published var fileName: String = ""
    @Published var name: String = ""
    @Published var customizationRef: String = ""
    @Published var prompt: String = ""
    @Published var promptFile: String = ""
    @Published var preflight: String = ""
    @Published var enabled: Bool = true
    // Legacy inline fields (shown only when no customization selected)
    @Published var agent: String = "default"
    @Published var model: String = ""
    @Published var workdir: String = ""

    // Schedule
    @Published var scheduleType: ScheduleType = .manual
    @Published var scheduleEvery: String = "30m"
    @Published var scheduleAt: String = "16:00"
    @Published var scheduleDays: [String] = []
    @Published var activeHoursStart: String = ""
    @Published var activeHoursEnd: String = ""

    var isNew: Bool { originalFileName.isEmpty }

    init() {}

    init(from flow: DispatchManager.Flow) {
        self.originalFileName = flow.fileName
        self.fileName = flow.fileName
        self.name = flow.name
        self.customizationRef = flow.customization ?? ""
        self.prompt = flow.prompt ?? ""
        self.promptFile = flow.promptFile ?? ""
        self.preflight = flow.preflight ?? ""
        self.enabled = flow.enabled
        self.agent = flow.agent ?? "default"
        self.model = flow.model ?? ""
        self.workdir = flow.workdir ?? ""

        switch flow.schedule {
        case .manual:
            self.scheduleType = .manual
        case .interval(let every, let days, let hours):
            self.scheduleType = .interval
            self.scheduleEvery = every
            self.scheduleDays = days ?? []
            if let h = hours, h.count == 2 {
                self.activeHoursStart = h[0]
                self.activeHoursEnd = h[1]
            }
        case .timeOfDay(let at, let days, let hours):
            self.scheduleType = .timeOfDay
            self.scheduleAt = at
            self.scheduleDays = days ?? []
            if let h = hours, h.count == 2 {
                self.activeHoursStart = h[0]
                self.activeHoursEnd = h[1]
            }
        }
    }

    static let commonIntervals = ["5m", "15m", "30m", "1h", "2h", "4h"]
    static let allDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    static let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri"]
}
