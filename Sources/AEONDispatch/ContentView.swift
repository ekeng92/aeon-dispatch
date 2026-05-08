import SwiftUI

struct ContentView: View {
    @ObservedObject var manager: DispatchManager
    @State private var editingFlow: FlowEditModel?
    @State private var showEditor = false
    @State private var editingCustomization: CustomizationEditModel?
    @State private var showCustEditor = false

    var body: some View {
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

                updateSection
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
        .frame(width: 380, height: 640)
        .sheet(isPresented: $showEditor) {
            if let model = editingFlow {
                FlowEditorView(manager: manager, edit: model)
            }
        }
        .sheet(isPresented: $showCustEditor) {
            if let model = editingCustomization {
                CustomizationEditorView(manager: manager, edit: model)
            }
        }
    }

    private func openEditor(for flow: DispatchManager.Flow) {
        editingFlow = manager.editModel(for: flow)
        showEditor = true
    }

    private func openNewFlowEditor() {
        editingFlow = manager.newFlowEditModel()
        showEditor = true
    }

    private func openCustEditor(for cust: DispatchManager.Customization) {
        editingCustomization = manager.customizationEditModel(for: cust)
        showCustEditor = true
    }

    private func openNewCustEditor() {
        editingCustomization = manager.newCustomizationEditModel()
        showCustEditor = true
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
                        Text("last: \(formatTimestamp(lastRun))")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            if manager.runningFlows.contains(flow.fileName) {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button(action: { openEditor(for: flow) }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
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

    // MARK: - Update

    private var updateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("UPDATE")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("v\(DispatchManager.buildVersion)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            if manager.updateInProgress {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Updating... your flows and config are safe.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if manager.updateAvailable {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.blue)
                        Text("Update available")
                            .font(.caption.weight(.medium))
                    }
                    if !manager.latestCommitMessage.isEmpty {
                        Text(manager.latestCommitMessage)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                    }
                    Button(action: { manager.performUpdate() }) {
                        Label("Update Now", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)
                    Text("Your flows, customizations, and config are preserved.")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            } else {
                HStack(spacing: 8) {
                    actionButton("Check for Updates", icon: "arrow.clockwise", tint: Color(.systemGray)) {
                        manager.checkForUpdate()
                    }
                    if manager.updateChecking {
                        ProgressView()
                            .controlSize(.small)
                    }
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

    private func formatTimestamp(_ iso: String) -> String {
        // Parse ISO timestamp and show relative time
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = df.date(from: iso) else {
            // Try without fractional seconds
            df.formatOptions = [.withInternetDateTime]
            guard let date = df.date(from: iso) else { return iso }
            return relativeTime(from: date)
        }
        return relativeTime(from: date)
    }

    private func relativeTime(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
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
}
