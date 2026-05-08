import SwiftUI

@main
struct AEONDispatchApp: App {
    @StateObject private var manager = DispatchManager()

    var body: some Scene {
        MenuBarExtra {
            ContentView(manager: manager)
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "bolt.fill")
                if manager.recentResultCount > 0 {
                    Text("\(manager.recentResultCount)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
