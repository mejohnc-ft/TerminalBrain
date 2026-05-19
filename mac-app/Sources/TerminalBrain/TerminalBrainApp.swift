import SwiftUI

@main
struct TerminalBrainApp: App {
    @StateObject private var model = BrainStatusModel()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup("Terminal Brain") {
            ContentView()
                .environmentObject(model)
                .environmentObject(settings)
                .frame(minWidth: 980, minHeight: 680)
                .task {
                    model.startControlAPI()
                    await model.refresh()
                }
        }
        .windowStyle(.titleBar)
        .commands {
            SidebarCommands()
            CommandMenu("Brain") {
                Button("Refresh Status") {
                    Task { await model.refresh() }
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Run Sync") {
                    Task { await model.runSyncNow() }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Button("Open Mission Control") {
                    model.openMissionControl()
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra("Terminal Brain", systemImage: "brain.head.profile") {
            Button("Refresh Status") {
                Task { await model.refresh() }
            }
            Button("Run Sync Now") {
                Task { await model.runSyncNow() }
            }
            Divider()
            Button("Open Mission Control") {
                model.openMissionControl()
            }
            Button("Open Logs") {
                model.openLogs()
            }
            Divider()
            Text(model.summaryLine)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}
