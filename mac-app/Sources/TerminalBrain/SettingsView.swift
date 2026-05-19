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
                LabeledContent("Mission Host", value: Paths.missionSSHHost)
                LabeledContent("Vault", value: Paths.workspace)
            }
            .padding(24)
            .frame(width: 520)
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
