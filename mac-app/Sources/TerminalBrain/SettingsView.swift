import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        TabView {
            Form {
                Picker("Theme", selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.label).tag(theme)
                    }
                }
                Toggle("Reduce glass effects", isOn: $settings.reduceGlass)
                Toggle("Simple operator navigation", isOn: $settings.operatorPathOnly)
                Toggle("Show advanced system surfaces", isOn: $settings.showAdvancedSystem)
            }
            .padding(24)
            .frame(width: 440)
            .tabItem {
                Label("Appearance", systemImage: "paintpalette")
            }

            Form {
                LabeledContent("Control API", value: "http://127.0.0.1:8765")
                LabeledContent("Bundle ID", value: "com.franklin.terminal-brain")
                TextField("Workspace", text: $settings.workspacePath)
                TextField("Mission URL", text: $settings.missionURLString)
                TextField("Mission SSH Host", text: $settings.missionSSHHost)
                TextField("Brain CLI", text: $settings.brainCLIPath)
                TextField("Sync Script", text: $settings.syncScriptPath)
                TextField("Sync Log", text: $settings.syncLogPath)
                Button {
                    settings.resetIntegrationDefaults()
                } label: {
                    Label("Reset Defaults", systemImage: "arrow.counterclockwise")
                }
                Text("Environment variables override these values: TERMINAL_BRAIN_WORKSPACE, TERMINAL_BRAIN_MISSION_URL, TERMINAL_BRAIN_MISSION_SSH_HOST, TERMINAL_BRAIN_CLI, TERMINAL_BRAIN_SYNC_SCRIPT, TERMINAL_BRAIN_SYNC_LOG.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(width: 680)
            .tabItem {
                Label("System", systemImage: "gearshape.2")
            }

            Form {
                LabeledContent("Apple Notes", value: "Explicit only")
                LabeledContent("Drafts", value: "Manual bridge")
                LabeledContent("Hourly Sync", value: "Unloaded")
                Text("Terminal Brain is the intended permission owner for sensitive local sources. Agents should use the terminal-brain MCP gateway instead of starting separate bridges.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(width: 520)
            .tabItem {
                Label("Permissions", systemImage: "lock.shield")
            }
        }
        .frame(minWidth: 520, minHeight: 320)
    }
}
