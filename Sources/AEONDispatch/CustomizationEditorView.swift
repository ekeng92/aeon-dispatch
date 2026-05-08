import SwiftUI

struct CustomizationEditorView: View {
    @ObservedObject var manager: DispatchManager
    @ObservedObject var edit: CustomizationEditModel
    var onDismiss: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text(edit.isNew ? "New Customization" : "Edit Customization")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider().padding(.horizontal, 16)

                // Identity
                sectionHeader("IDENTITY")
                VStack(alignment: .leading, spacing: 8) {
                    labeledField("Name") {
                        TextField("e.g. HI PR Reviewer", text: $edit.name)
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
                    .help("The JSON filename in ~/.aeon-dispatch/customizations/. Leave blank to auto-generate from the name.")

                    labeledField("Description") {
                        TextField("What this customization is for", text: $edit.description)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                Divider().padding(.horizontal, 16)

                // Execution Context
                sectionHeader("EXECUTION CONTEXT")
                VStack(alignment: .leading, spacing: 8) {
                    labeledField("Agent") {
                        TextField("default", text: $edit.agent)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.caption, design: .monospaced))
                    }
                    .help("Copilot agent mode. Use 'default' for no specific agent, or a custom mode like 'alpha-dev'.")

                    labeledField("Model") {
                        TextField("(use agent default)", text: $edit.model)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.caption, design: .monospaced))
                    }
                    .help("LLM model override. Leave blank to use the agent's default model.")

                    labeledField("Working Directory") {
                        HStack(spacing: 6) {
                            TextField("~/IdeaProjects/repo-name", text: $edit.workdir)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.caption, design: .monospaced))
                            Button(action: browseFolder) {
                                Image(systemName: "folder")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    Text("The working directory determines which repo's skills, instructions, and agents are available to copilot.")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                Divider().padding(.horizontal, 16)

                // Prompt File
                sectionHeader("PROMPT FILE (OPTIONAL)")
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        TextField("~/path/to/prompt.md", text: $edit.promptFile)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.caption, design: .monospaced))
                        Button(action: browseFile) {
                            Image(systemName: "doc")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text("Default prompt file for flows using this customization. Flows can override with their own prompt.")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                Divider().padding(.horizontal, 16)

                // Usage summary
                if !edit.isNew {
                    sectionHeader("USED BY")
                    let usedBy = manager.flows.filter { $0.customization == edit.originalFileName }
                    if usedBy.isEmpty {
                        Text("No flows reference this customization.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(usedBy) { flow in
                                HStack(spacing: 6) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.blue)
                                    Text(flow.name)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }

                    Divider().padding(.horizontal, 16)
                }

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
                    .disabled(edit.name.isEmpty || edit.agent.isEmpty)
                }
                .padding(16)
            }
        }
        .frame(width: 380, height: 640)
        .alert("Delete Customization?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let cust = manager.customizations.first(where: { $0.fileName == edit.originalFileName }) {
                    manager.deleteCustomization(cust)
                }
                onDismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(edit.name)\". Flows referencing it will fall back to inline config.")
        }
    }

    // MARK: - Actions

    private func save() {
        manager.saveCustomization(edit)
        onDismiss()
    }

    private func browseFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a prompt file"
        if panel.runModal() == .OK, let url = panel.url {
            let path = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
            edit.promptFile = path
        }
    }

    private func browseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select the working directory"
        if panel.runModal() == .OK, let url = panel.url {
            let path = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
            edit.workdir = path
        }
    }

    // MARK: - Sub-views

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
}
