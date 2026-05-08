import SwiftUI

struct FlowEditorView: View {
    @ObservedObject var manager: DispatchManager
    @ObservedObject var edit: FlowEditModel
    var onDismiss: () -> Void

    @State private var showDeleteConfirm = false
    @State private var promptSource: PromptSource = .inline

    enum PromptSource: String, CaseIterable {
        case inline = "Inline"
        case file = "Prompt File"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text(edit.isNew ? "New Flow" : "Edit Flow")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Toggle("Enabled", isOn: $edit.enabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                    Text(edit.enabled ? "On" : "Off")
                        .font(.caption)
                        .foregroundStyle(edit.enabled ? .green : .secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider().padding(.horizontal, 16)

                // Identity
                sectionHeader("IDENTITY")
                VStack(alignment: .leading, spacing: 8) {
                    labeledField("Name") {
                        TextField("e.g. PR Review (API + Web)", text: $edit.name)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                    }
                    labeledField("File Name") {
                        HStack(spacing: 4) {
                            TextField("auto-generated from name", text: $edit.fileName)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.caption, design: .monospaced))
                            Text(".json")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .help("The JSON filename in ~/.aeon-dispatch/flows/. Leave blank to auto-generate from the name.")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                Divider().padding(.horizontal, 16)

                // Prompt
                sectionHeader("PROMPT")
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Source", selection: $promptSource) {
                        ForEach(PromptSource.allCases, id: \.self) { source in
                            Text(source.rawValue).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: promptSource) { _ in
                        // Clear the other source when switching
                        if promptSource == .inline { edit.promptFile = "" }
                        else { edit.prompt = "" }
                    }

                    if promptSource == .inline {
                        TextEditor(text: $edit.prompt)
                            .font(.system(.caption, design: .monospaced))
                            .frame(minHeight: 80, maxHeight: 120)
                            .scrollContentBackground(.hidden)
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(.quaternary)
                            )
                        Text("The prompt sent to copilot CLI. Use /skill-name to invoke skills.")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    } else {
                        HStack(spacing: 6) {
                            TextField("~/path/to/prompt.md", text: $edit.promptFile)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.caption, design: .monospaced))
                            Button(action: { browseFile(for: \.promptFile) }) {
                                Image(systemName: "folder")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        Text("Path to a .md file containing the prompt. Supports ~ expansion.")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                Divider().padding(.horizontal, 16)

                // Execution Context
                sectionHeader("EXECUTION CONTEXT")
                VStack(alignment: .leading, spacing: 8) {
                    labeledField("Customization") {
                        Picker("", selection: $edit.customizationRef) {
                            Text("None (inline config)")
                                .tag("")
                            ForEach(manager.customizations) { cust in
                                Text("\(cust.name) (\(cust.subtitle))")
                                    .tag(cust.fileName)
                            }
                        }
                        .labelsHidden()
                    }
                    .help("Select a customization to inherit agent, model, and working directory from it.")

                    if edit.customizationRef.isEmpty {
                        // Inline fields when no customization is selected
                        labeledField("Agent") {
                            TextField("default", text: $edit.agent)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.caption, design: .monospaced))
                        }

                        labeledField("Model") {
                            TextField("(use agent default)", text: $edit.model)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.caption, design: .monospaced))
                        }

                        labeledField("Working Directory") {
                            HStack(spacing: 6) {
                                TextField("~/IdeaProjects/repo-name", text: $edit.workdir)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.caption, design: .monospaced))
                                Button(action: { browseFolder(for: \.workdir) }) {
                                    Image(systemName: "folder")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        contextHelp
                    } else if let cust = manager.customization(named: edit.customizationRef) {
                        // Show resolved values from the customization (read-only)
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Agent").font(.system(size: 9)).foregroundStyle(.tertiary)
                                Text(cust.agent).font(.system(.caption, design: .monospaced))
                            }
                            if let m = cust.model, !m.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Model").font(.system(size: 9)).foregroundStyle(.tertiary)
                                    Text(m).font(.system(.caption, design: .monospaced))
                                }
                            }
                        }
                        if let w = cust.workdir, !w.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Working Dir").font(.system(size: 9)).foregroundStyle(.tertiary)
                                Text(w).font(.system(.caption, design: .monospaced))
                            }
                        }
                        Text("Inherited from customization. Edit the customization to change these values.")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }

                    labeledField("Preflight Gate") {
                        TextField("shell command (must exit 0)", text: $edit.preflight)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.caption, design: .monospaced))
                    }
                    .help("Shell command that must exit 0 for the flow to run. Saves compute when there's nothing to do.")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                Divider().padding(.horizontal, 16)

                // Schedule
                sectionHeader("SCHEDULE")
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Type", selection: $edit.scheduleType) {
                        ForEach(ScheduleType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    if edit.scheduleType == .interval {
                        labeledField("Every") {
                            Picker("", selection: $edit.scheduleEvery) {
                                ForEach(FlowEditModel.commonIntervals, id: \.self) { interval in
                                    Text(interval).tag(interval)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 100)
                        }
                    }

                    if edit.scheduleType == .timeOfDay {
                        labeledField("At") {
                            TextField("HH:MM", text: $edit.scheduleAt)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: 80)
                        }
                    }

                    if edit.scheduleType != .manual {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                ForEach(FlowEditModel.allDays, id: \.self) { day in
                                    dayToggle(day)
                                }
                                Spacer()
                                Button("Weekdays") {
                                    edit.scheduleDays = FlowEditModel.weekdays
                                }
                                .font(.system(size: 9))
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                        }

                        HStack(spacing: 8) {
                            labeledField("Active from") {
                                TextField("09:00", text: $edit.activeHoursStart)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(maxWidth: 70)
                            }
                            labeledField("to") {
                                TextField("18:00", text: $edit.activeHoursEnd)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(maxWidth: 70)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                Divider().padding(.horizontal, 16)

                // Action buttons
                HStack(spacing: 8) {
                    if !edit.isNew {
                        Button(action: { showDeleteConfirm = true }) {
                            Label("Delete", systemImage: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .controlSize(.small)
                    }

                    Spacer()

                    Button(action: { onDismiss() }) {
                        Text("Cancel")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(action: save) {
                        Text(edit.isNew ? "Create" : "Save")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)
                    .disabled(edit.name.isEmpty || (edit.prompt.isEmpty && edit.promptFile.isEmpty && edit.customizationRef.isEmpty))
                }
                .padding(16)
            }
        }
        .frame(width: 380, height: 640)
        .onAppear {
            promptSource = edit.promptFile.isEmpty ? .inline : .file
        }
        .alert("Delete Flow?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let flow = manager.flows.first(where: { $0.fileName == edit.originalFileName }) {
                    manager.deleteFlow(flow)
                }
                onDismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(edit.name)\".")
        }
    }

    // MARK: - Actions

    private func save() {
        manager.saveFlow(edit)
        onDismiss()
    }

    private func browseFile(for keyPath: ReferenceWritableKeyPath<FlowEditModel, String>) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a prompt file"
        if panel.runModal() == .OK, let url = panel.url {
            // Convert to ~ path for portability
            let path = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
            edit[keyPath: keyPath] = path
        }
    }

    private func browseFolder(for keyPath: ReferenceWritableKeyPath<FlowEditModel, String>) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select the working directory"
        if panel.runModal() == .OK, let url = panel.url {
            let path = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
            edit[keyPath: keyPath] = path
        }
    }

    // MARK: - Sub-views

    private var contextHelp: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("The working directory determines which repo's skills, instructions, and agents are available to copilot.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Text("For multi-repo skills (e.g. /hip-reviewer), point to the AI Toolshed repo or a .code-workspace file's parent.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)
    }

    private func labeledField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func dayToggle(_ day: String) -> some View {
        let isSelected = edit.scheduleDays.contains(day)
        return Button(action: {
            if isSelected {
                edit.scheduleDays.removeAll { $0 == day }
            } else {
                edit.scheduleDays.append(day)
            }
        }) {
            Text(String(day.prefix(2)))
                .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                .frame(width: 28, height: 24)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .blue : Color(.systemGray))
        .controlSize(.mini)
    }
}
