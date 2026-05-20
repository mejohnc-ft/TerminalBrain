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

                Button("Ask Current Focus") {
                    Task { await model.askFocusOracle(model.focusItem) }
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Button("Copy Operator Snapshot") {
                    Task { await model.copyOperatorSnapshot() }
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Button("Copy Now") {
                    Task { await model.copyNow() }
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button("Copy Process Map") {
                    Task { await model.copyProcessMap() }
                }

                Button("Copy Cleanup Plan") {
                    Task { await model.copyCleanupPlan() }
                }

                Button("Copy Support Bundle") {
                    Task { await model.copySupportBundle() }
                }

                Button("Copy Start Here") {
                    Task { await model.copyStartHere() }
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])

                Button("Copy Value Brief") {
                    Task { await model.copyValueBrief() }
                }

                Button("Copy Oracle Brief") {
                    Task { await model.copyOracleBrief() }
                }

                Button("Copy Operator Brief") {
                    Task { await model.copyOperatorBrief() }
                }

                Button("Copy Decision Lane") {
                    Task { await model.copyDecisionLane() }
                }

                Button("Copy Idea Pulse") {
                    Task { await model.copyIdeaPulse() }
                }

                Button("Copy Project Memory") {
                    Task { await model.copyProjectMemory() }
                }

                Button("Copy Operator Deck") {
                    Task { await model.copyOperatorDeck() }
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])

                Button("Copy Agent Prompt") {
                    Task { await model.copyAgentPrompt() }
                }

                Button("Open Latest Context Pack") {
                    model.openLatestContextPack()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Button("Copy Latest Context Pack") {
                    Task { await model.copyLatestContextPack() }
                }

                Button("Copy Agent Handoff") {
                    Task { await model.copyHandoff() }
                }

                Button("Open Mission Control") {
                    model.openMissionControl()
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra("Terminal Brain", systemImage: "brain.head.profile") {
            Text("Focus: \(model.focusItem.title)")
            Button("Copy Now") {
                Task { await model.copyNow() }
            }
            Button("Copy Process Map") {
                Task { await model.copyProcessMap() }
            }
            Button("Copy Cleanup Plan") {
                Task { await model.copyCleanupPlan() }
            }
            Button("Copy Support Bundle") {
                Task { await model.copySupportBundle() }
            }
            Button("Copy Start Here") {
                Task { await model.copyStartHere() }
            }
            Button("Copy Oracle Brief") {
                Task { await model.copyOracleBrief() }
            }
            Button("Ask Current Focus") {
                Task { await model.askFocusOracle(model.focusItem) }
            }
            Button("Build Focus Pack") {
                model.workQuery = model.focusItem.query.isEmpty ? model.focusItem.title : model.focusItem.query
                Task { await model.startWork() }
            }
            Button("Open Latest Context Pack") {
                model.openLatestContextPack()
            }
            Button("Copy Latest Context Pack") {
                Task { await model.copyLatestContextPack() }
            }
            Button("Copy Agent Handoff") {
                Task { await model.copyHandoff() }
            }
            Button("Copy Agent Prompt") {
                Task { await model.copyAgentPrompt() }
            }
            Button("Copy Operator Brief") {
                Task { await model.copyOperatorBrief() }
            }
            Button("Copy Value Brief") {
                Task { await model.copyValueBrief() }
            }
            Button("Copy Decision Lane") {
                Task { await model.copyDecisionLane() }
            }
            Button("Copy Idea Pulse") {
                Task { await model.copyIdeaPulse() }
            }
            Button("Copy Project Memory") {
                Task { await model.copyProjectMemory() }
            }
            Divider()
            Button("Refresh Status") {
                Task { await model.refresh() }
            }
            Button("Run Sync Now") {
                Task { await model.runSyncNow() }
            }
            Button("Copy Operator Snapshot") {
                Task { await model.copyOperatorSnapshot() }
            }
            Button("Copy Operator Deck") {
                Task { await model.copyOperatorDeck() }
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
