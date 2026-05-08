import SwiftUI
import AppKit
import Combine

// MARK: - Debug Logger

private let logFile: URL = URL(fileURLWithPath: "/tmp/aeon-dispatch.log")
private let logHandle: FileHandle? = {
    FileManager.default.createFile(atPath: logFile.path, contents: nil)
    return try? FileHandle(forWritingTo: logFile)
}()

func log(_ msg: String, category: String = "UI") {
    let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    let line = "[\(ts)] [\(category)] \(msg)\n"
    print(line, terminator: "")                          // stdout (visible in swift run)
    logHandle?.write(Data(line.utf8))                    // /tmp/aeon-dispatch.log (visible via tail)
}

// MARK: - App Entry Point

@main
struct AEONDispatchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

// MARK: - Window Manager

final class WindowManager {
    static let shared = WindowManager()
    private var windows: [String: NSWindow] = [:]

    func openEditor<V: View>(id: String, title: String, size: NSSize, content: V) {
        if let existing = windows[id], existing.isVisible {
            log("openEditor[\(id)] — already visible, bringing to front", category: "WindowManager")
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        log("openEditor[\(id)] — creating new window title='\(title)' size=\(size)", category: "WindowManager")
        let window = NSWindow(contentViewController: NSHostingController(rootView: content))
        window.title = title
        window.setContentSize(size)
        window.styleMask = [.titled, .closable]
        window.level = .floating   // must sit above the .floating NSPanel
        window.isReleasedWhenClosed = false
        window.center()
        log("openEditor[\(id)] — window.level=\(window.level.rawValue) (floating=\(NSWindow.Level.floating.rawValue))", category: "WindowManager")
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        windows[id] = window
        log("openEditor[\(id)] — done, isVisible=\(window.isVisible) isKeyWindow=\(window.isKeyWindow)", category: "WindowManager")
    }

    func closeEditor(id: String) {
        log("closeEditor[\(id)]", category: "WindowManager")
        windows[id]?.close()
        windows.removeValue(forKey: id)
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private let manager = DispatchManager()
    private var cancellable: AnyCancellable?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        log("applicationDidFinishLaunching", category: "AppDelegate")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.action = #selector(togglePanel)
            button.target = self
            updateIcon()
        }

        let panelSize = NSSize(width: 380, height: 640)
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.isReleasedWhenClosed = false
        panel.hasShadow = true
        panel.backgroundColor = .windowBackgroundColor
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .utilityWindow

        log("panel created — level=\(panel.level.rawValue) styleMask=\(panel.styleMask.rawValue)", category: "AppDelegate")

        let hostingView = NSHostingView(
            rootView: ContentView(manager: manager, closePanel: { [weak self] in
                self?.closePanel()
            })
        )
        panel.contentView = hostingView

        cancellable = manager.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.updateIcon() }
        }

        log("applicationDidFinishLaunching — complete", category: "AppDelegate")
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        button.image = tintedMenuBarIcon("bolt.fill", color: .systemGreen)

        if manager.recentResultCount > 0 {
            button.attributedTitle = NSAttributedString(
                string: " \(manager.recentResultCount)",
                attributes: [
                    .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .bold),
                    .baselineOffset: 1
                ]
            )
        } else {
            button.title = ""
        }
    }

    private func tintedMenuBarIcon(_ name: String, color: NSColor) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return NSImage() }
        let size = symbol.size
        let result = NSImage(size: size)
        result.lockFocus()
        symbol.draw(in: NSRect(origin: .zero, size: size),
                    from: .zero, operation: .sourceOver, fraction: 1.0)
        color.set()
        NSRect(origin: .zero, size: size).fill(using: .sourceAtop)
        result.unlockFocus()
        result.isTemplate = false
        return result
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            log("togglePanel — panel visible, closing", category: "AppDelegate")
            closePanel()
        } else {
            log("togglePanel — opening panel", category: "AppDelegate")
            positionPanelBelowStatusItem()
            panel.makeKeyAndOrderFront(nil)
            log("togglePanel — panel origin=\(panel.frame.origin) size=\(panel.frame.size) isVisible=\(panel.isVisible)", category: "AppDelegate")

            globalMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown]
            ) { [weak self] event in
                log("globalMonitor — click outside app, closing panel", category: "EventMonitor")
                self?.closePanel()
            }

            localMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown]
            ) { [weak self] event in
                guard let self else { return event }
                let windowDesc = event.window.map { w in
                    "level=\(w.level.rawValue) class=\(type(of: w)) title='\(w.title)'"
                } ?? "nil"
                log("localMonitor — click in window: \(windowDesc)", category: "EventMonitor")

                if event.window === self.panel {
                    log("localMonitor — hit panel, pass through", category: "EventMonitor")
                    return event
                }
                if event.window === self.statusItem.button?.window {
                    log("localMonitor — hit status bar button, pass through (togglePanel handles it)", category: "EventMonitor")
                    return event
                }
                if let w = event.window, w.level == .floating {
                    log("localMonitor — hit floating window (editor), pass through", category: "EventMonitor")
                    return event
                }
                log("localMonitor — unhandled window, closing panel", category: "EventMonitor")
                self.closePanel()
                return event
            }
        }
    }

    private func positionPanelBelowStatusItem() {
        guard let button = statusItem.button,
              let buttonWindow = button.window else { return }
        let buttonRect = button.convert(button.bounds, to: nil)
        let screenRect = buttonWindow.convertToScreen(buttonRect)

        let panelWidth = panel.frame.width
        let panelHeight = panel.frame.height
        var x = screenRect.midX - panelWidth / 2
        let y = screenRect.minY - panelHeight - 4

        if let screen = NSScreen.main {
            let maxX = screen.visibleFrame.maxX
            let minX = screen.visibleFrame.minX
            if x + panelWidth > maxX { x = maxX - panelWidth }
            if x < minX { x = minX }
        }

        log("positionPanel — statusItemMidX=\(screenRect.midX) panelOrigin=(\(x),\(y))", category: "AppDelegate")
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func closePanel() {
        log("closePanel — removing monitors, hiding panel", category: "AppDelegate")
        panel.orderOut(nil)
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
    }
}
