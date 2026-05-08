import SwiftUI

struct ContentView: View {
    @ObservedObject var manager: DispatchManager
    var closePanel: () -> Void = {}

    // Import sheet state
    @State private var showingImportSheet = false
    @State private var importCandidates: [DispatchManager.ImportCandidate] = []
    @State private var importDirectory: URL? = nil

    var body: some View {
        mainList
            .frame(width: 380, height: 640)
            .sheet(isPresented: $showingImportSheet) {
                ImportSheetView(
                    candidates: $importCandidates,
                    directory: importDirectory,
                    onImport: { selected in
                        manager.importCandidates(selected)
                        showingImportSheet = false
                    },
                    onCancel: { showingImportSheet = false }
                )
            }
    }

    private var mainList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                statusCard
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                Divider().padding(.horizontal, 16)

                customizationsList
                    .padding(16)

                Divider().padding(.horizontal, 16)

                flowsList
                    .padding(16)

                Divider().padding(.horizontal, 16)

                recentResultsList
                    .padding(16)

                Divider().padding(.horizontal, 16)

                quickActions
                    .padding(16)

                Divider().padding(.horizontal, 16)

                activitySection
                    .padding(16)

                Divider()

                Button(action: { NSApp.terminate(nil) }) {
                    Text("Quit AEON Dispatch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 10)
            }
        }
    }

    /// Closes the panel, then fires `action` after a brief delay so the panel
    /// has fully dismissed before the editor window claims key focus.
    /// All four editor-launch paths go through here.
    private func afterPanelClose(_ action: @escaping () -> Void) {
        closePanel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: action)
    }

    private func openEditor(for flow: DispatchManager.Flow) {
        let model = manager.editModel(for: flow)
        let editorId = "flow-\(flow.fileName)"
        afterPanelClose {
            WindowManager.shared.openEditor(
                id: editorId,
                title: "Edit Flow: \(flow.name)",
                size: NSSize(width: 380, height: 640),
                content: FlowEditorView(
                    manager: manager,
                    edit: model,
                    onDismiss: { WindowManager.shared.closeEditor(id: editorId) }
                )
            )
        }
    }

    private func openNewFlowEditor() {
        let model = manager.newFlowEditModel()
        let editorId = "flow-new"
        afterPanelClose {
            WindowManager.shared.openEditor(
                id: editorId,
                title: "New Flow",
                size: NSSize(width: 380, height: 640),
                content: FlowEditorView(
                    manager: manager,
                    edit: model,
                    onDismiss: { WindowManager.shared.closeEditor(id: editorId) }
                )
            )
        }
    }

    private func openCustEditor(for cust: DispatchManager.Customization) {
        let model = manager.customizationEditModel(for: cust)
        let editorId = "cust-\(cust.fileName)"
        afterPanelClose {
            WindowManager.shared.openEditor(
                id: editorId,
                title: "Edit Customization: \(cust.name)",
                size: NSSize(width: 380, height: 640),
                content: CustomizationEditorView(
                    manager: manager,
                    edit: model,
                    onDismiss: { WindowManager.shared.closeEditor(id: editorId) }
                )
            )
        }
    }

    private func openNewCustEditor() {
        let model = manager.newCustomizationEditModel()
        let editorId = "cust-new"
        afterPanelClose {
            WindowManager.shared.openEditor(
                id: editorId,
                title: "New Customization",
                size: NSSize(width: 380, height: 640),
                content: CustomizationEditorView(
                    manager: manager,
                    edit: model,
                    onDismiss: { WindowManager.shared.closeEditor(id: editorId) }
                )
            )
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(statusColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.system(size: 16, weight: .semibold))
                    Text(statusSubtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(countsText)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }

            HStack(spacing: 16) {
                depIndicator("dispatch", ok: manager.dispatchBinAvailable)
                depIndicator("copilot", ok: manager.copilotAvailable)
            }
            .font(.caption2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.quaternary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Customizations List

    private var customizationsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("CUSTOMIZATIONS")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                // Import from a directory (e.g. .github/, contrib/ekeng/)
                Button(action: beginImport) {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .font(.system(size: 10))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(.cyan)
                .help("Import customizations from a folder (.instructions.md, SKILL.md, .agent.md, ...)")

                Button(action: openNewCustEditor) {
                    Label("New", systemImage: "plus")
                        .font(.system(size: 10))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(.purple)
            }

            if manager.customizations.isEmpty {
                Text("No customizations defined")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(manager.customizations) { cust in
                        customizationRow(cust)
                    }
                }
            }
        }
    }

    private func customizationRow(_ cust: DispatchManager.Customization) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 10))
                .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 1) {
                Text(cust.name)
                    .font(.caption.weight(.medium))
                Text(cust.subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            let usageCount = manager.flows.filter { $0.customization == cust.fileName }.count
            if usageCount > 0 {
                Text("\(usageCount)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(.quaternary))
                    .help("\(usageCount) flow(s) using this customization")
            }

            Button(action: { openCustEditor(for: cust) }) {
                Image(systemName: "pencil")
                    .font(.system(size: 10))
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .help("Edit \(cust.name)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.quaternary)
        }
    }

    // MARK: - Flows List

    private var flowsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("FLOWS")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: openNewFlowEditor) {
                    Label("New", systemImage: "plus")
                        .font(.system(size: 10))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(.green)
            }

            if manager.flows.isEmpty {
                Text("No flows configured")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(manager.flows) { flow in
                        flowRow(flow)
                    }
                }
            }
        }
    }

    private func flowRow(_ flow: DispatchManager.Flow) -> some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(flowStatusColor(flow))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(flow.name)
                        .font(.caption.weight(.medium))
                    if !flow.enabled {
                        Text("OFF")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule().fill(.quaternary)
                            )
                    }
                }

                HStack(spacing: 6) {
                    Text(flow.schedule.displayString)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    if let lastRun = manager.lastRunTimes[flow.fileName] {
                        Text("last: \(formatISOTimestamp(lastRun))")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            if manager.runningFlows.contains(flow.fileName) {
                // Show a live terminal link while the flow is executing
                Button(action: { openTerminalForFlow(flow) }) {
                    Image(systemName: "terminal")
                        .font(.system(size: 10))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(.green)
                .help("Open live output in Terminal")

                ProgressView()
                    .controlSize(.small)
            } else {
                Button(action: { openEditor(for: flow) }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(.orange)
                .help("Edit \(flow.name)")

                Button(action: { manager.runFlow(flow) }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(.blue)
                .help("Run \(flow.name) now")
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.quaternary.opacity(0.5))
        }
    }

    // MARK: - Recent Results

    private var recentResultsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RECENT RESULTS")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            if manager.recentResults.isEmpty {
                Text("No results yet")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 4) {
                    ForEach(manager.recentResults.prefix(5)) { result in
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(result.flowId)
                                    .font(.caption.weight(.medium))
                                Text(result.dateString)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Button(action: { manager.copyResultToClipboard(result) }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 9))
                            }
                            .buttonStyle(.borderless)
                            .help("Copy to clipboard")

                            Button(action: { manager.openResult(result) }) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 9))
                            }
                            .buttonStyle(.borderless)
                            .help("Open in editor")
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACTIONS")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                actionButton("Open Flows", icon: "folder", tint: .blue) {
                    manager.openFlowsFolder()
                }
                actionButton("Open Results", icon: "tray.full", tint: .blue) {
                    manager.openResultsFolder()
                }
            }

            HStack(spacing: 8) {
                if manager.schedulerRunning {
                    actionButton("Stop Scheduler", icon: "stop.fill", tint: .red) {
                        manager.uninstallScheduler()
                    }
                } else {
                    actionButton("Start Scheduler", icon: "play.fill", tint: .green) {
                        manager.installScheduler()
                    }
                }
                actionButton("Refresh", icon: "arrow.clockwise", tint: Color(.systemGray)) {
                    manager.refresh()
                }
            }
        }
    }

    // MARK: - Activity Log

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACTIVITY")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            if manager.activityLog.isEmpty {
                Text("No activity yet")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(manager.activityLog.prefix(8)) { entry in
                        HStack(alignment: .top, spacing: 6) {
                            Text(entry.timeString)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.tertiary)
                            Text(entry.message)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        if !manager.dispatchBinAvailable { return .red }
        if !manager.runningFlows.isEmpty { return .blue }
        if manager.schedulerRunning { return .green }
        return .orange
    }

    private var statusTitle: String {
        if !manager.dispatchBinAvailable { return "Not Configured" }
        if !manager.runningFlows.isEmpty { return "Running" }
        if manager.schedulerRunning { return "Scheduler Active" }
        return "Scheduler Stopped"
    }

    private var statusSubtitle: String {
        if !manager.dispatchBinAvailable {
            return "dispatch binary not found at ~/.local/bin/dispatch"
        }
        if !manager.runningFlows.isEmpty {
            let names = manager.runningFlows.sorted().joined(separator: ", ")
            return "Executing: \(names)"
        }
        if manager.schedulerRunning {
            return "Flows are checked automatically via launchd"
        }
        return "Install the scheduler to run flows automatically"
    }

    private var countsText: String {
        let flowCount = manager.flows.count
        let enabled = manager.flows.filter(\.enabled).count
        let results = manager.recentResultCount
        return "\(enabled)/\(flowCount) flows enabled, \(results) results today"
    }

    private func flowStatusColor(_ flow: DispatchManager.Flow) -> Color {
        if manager.runningFlows.contains(flow.fileName) { return .blue }
        if !flow.enabled { return .gray }
        if manager.lastRunTimes[flow.fileName] != nil { return .green }
        return .orange
    }

    private func depIndicator(_ name: String, ok: Bool) -> some View {
        HStack(spacing: 3) {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(ok ? .green : .red)
            Text(name)
        }
    }

    private func actionButton(_ title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(tint)
        .controlSize(.small)
    }

    // MARK: - Import

    /// Open a folder picker, scan for importable files, then show the preview sheet.
    private func beginImport() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Folder"
        panel.message = "Select a folder to scan for customization files (.instructions.md, SKILL.md, .agent.md ...)"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let candidates = manager.scanImportCandidates(in: url)
        importDirectory = url
        importCandidates = candidates
        showingImportSheet = true
    }

    // MARK: - Terminal

    /// Open Terminal.app tailing the live log file for the given flow.
    private func openTerminalForFlow(_ flow: DispatchManager.Flow) {
        let logPath = manager.flowLogPath(for: flow.fileName)
        // Ensure the log file exists so tail doesn't error immediately
        FileManager.default.createFile(atPath: logPath, contents: nil)
        let script = "tell application \"Terminal\" to do script \"echo 'AEON Dispatch — \(flow.name)'; tail -f \\\"\(logPath)\\\"\""
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
    }
}

// MARK: - Import Sheet

/// Preview sheet shown before committing the import.
/// The user can toggle individual candidates on/off before pressing Import.
struct ImportSheetView: View {
    @Binding var candidates: [DispatchManager.ImportCandidate]
    let directory: URL?
    let onImport: ([DispatchManager.ImportCandidate]) -> Void
    let onCancel: () -> Void

    private var selectedCount: Int { candidates.filter(\.selected).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Import Customizations")
                    .font(.headline)
                if let dir = directory {
                    Text(dir.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .padding()

            Divider()

            if candidates.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No importable files found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Looking for: SKILL.md, *.instructions.md, *.agent.md, *.prompt.md, *.chatmode.md")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // Toggle-all row
                HStack {
                    Button(selectedCount == candidates.count ? "Deselect All" : "Select All") {
                        let allSelected = selectedCount == candidates.count
                        for i in candidates.indices { candidates[i].selected = !allSelected }
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                    Spacer()
                    Text("\(selectedCount) of \(candidates.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)

                Divider()

                // Candidate list
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(candidates.indices, id: \.self) { i in
                            HStack(spacing: 8) {
                                Toggle("", isOn: $candidates[i].selected)
                                    .labelsHidden()
                                    .toggleStyle(.checkbox)

                                typeIcon(candidates[i].fileType)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(candidates[i].name)
                                        .font(.caption.weight(.medium))
                                    Text(candidates[i].promptFile
                                        .replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                                        .font(.system(size: 9))
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }

                                Spacer()

                                Text(candidates[i].fileType)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(.quaternary))
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

            // Footer buttons
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.escape)
                Spacer()
                Button(
                    action: { onImport(candidates) },
                    label: {
                        Text(candidates.isEmpty
                             ? "Nothing to Import"
                             : "Import \(selectedCount) Customization\(selectedCount == 1 ? "" : "s")")
                    }
                )
                .buttonStyle(.borderedProminent)
                .disabled(selectedCount == 0)
                .keyboardShortcut(.return)
            }
            .padding()
        }
        .frame(width: 480, height: 420)
    }

    @ViewBuilder
    private func typeIcon(_ type: String) -> some View {
        switch type {
        case "skill":
            Image(systemName: "wrench.and.screwdriver.fill").foregroundStyle(.orange)
        case "instruction":
            Image(systemName: "doc.text.fill").foregroundStyle(.blue)
        case "agent":
            Image(systemName: "person.fill").foregroundStyle(.purple)
        case "prompt":
            Image(systemName: "text.bubble.fill").foregroundStyle(.green)
        default:
            Image(systemName: "doc.fill").foregroundStyle(.secondary)
        }
    }
}
