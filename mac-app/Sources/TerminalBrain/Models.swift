import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case arctic
    case graphite
    case midnight

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .arctic: return "Arctic Glass"
        case .graphite: return "Graphite"
        case .midnight: return "Midnight"
        }
    }

    var accent: Color {
        switch self {
        case .system: return Color(red: 0.12, green: 0.34, blue: 0.30)
        case .arctic: return Color(red: 0.05, green: 0.43, blue: 0.48)
        case .graphite: return Color(red: 0.24, green: 0.27, blue: 0.30)
        case .midnight: return Color(red: 0.26, green: 0.42, blue: 0.84)
        }
    }

    var background: [Color] {
        switch self {
        case .system:
            return [Color(red: 0.08, green: 0.08, blue: 0.09), Color(red: 0.12, green: 0.12, blue: 0.14)]
        case .arctic:
            return [Color(red: 0.92, green: 0.97, blue: 0.97), Color(red: 0.82, green: 0.90, blue: 0.94)]
        case .graphite:
            return [Color(red: 0.12, green: 0.12, blue: 0.13), Color(red: 0.18, green: 0.18, blue: 0.19)]
        case .midnight:
            return [Color(red: 0.08, green: 0.10, blue: 0.14), Color(red: 0.12, green: 0.17, blue: 0.24)]
        }
    }

    var primaryText: Color {
        switch self {
        case .system, .graphite, .midnight: return Color(red: 0.93, green: 0.96, blue: 0.96)
        default: return Color(red: 0.10, green: 0.15, blue: 0.14)
        }
    }

    var secondaryText: Color {
        switch self {
        case .system, .graphite, .midnight: return Color(red: 0.70, green: 0.77, blue: 0.80)
        default: return Color(red: 0.32, green: 0.37, blue: 0.36)
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "terminalBrainTheme") }
    }
    @Published var reduceGlass: Bool {
        didSet { UserDefaults.standard.set(reduceGlass, forKey: "terminalBrainReduceGlass") }
    }
    @Published var showAdvancedSystem: Bool {
        didSet { UserDefaults.standard.set(showAdvancedSystem, forKey: "terminalBrainShowAdvancedSystem") }
    }
    @Published var workspacePath: String {
        didSet { UserDefaults.standard.set(workspacePath, forKey: AppConfig.Keys.workspacePath) }
    }
    @Published var missionURLString: String {
        didSet { UserDefaults.standard.set(missionURLString, forKey: AppConfig.Keys.missionURLString) }
    }
    @Published var missionSSHHost: String {
        didSet { UserDefaults.standard.set(missionSSHHost, forKey: AppConfig.Keys.missionSSHHost) }
    }
    @Published var brainCLIPath: String {
        didSet { UserDefaults.standard.set(brainCLIPath, forKey: AppConfig.Keys.brainCLIPath) }
    }
    @Published var syncScriptPath: String {
        didSet { UserDefaults.standard.set(syncScriptPath, forKey: AppConfig.Keys.syncScriptPath) }
    }
    @Published var syncLogPath: String {
        didSet { UserDefaults.standard.set(syncLogPath, forKey: AppConfig.Keys.syncLogPath) }
    }

    init() {
        let rawTheme = UserDefaults.standard.string(forKey: "terminalBrainTheme") ?? AppTheme.midnight.rawValue
        theme = AppTheme(rawValue: rawTheme) ?? .system
        reduceGlass = UserDefaults.standard.bool(forKey: "terminalBrainReduceGlass")
        showAdvancedSystem = UserDefaults.standard.bool(forKey: "terminalBrainShowAdvancedSystem")
        workspacePath = AppConfig.workspacePath
        missionURLString = AppConfig.missionURLString
        missionSSHHost = AppConfig.missionSSHHost
        brainCLIPath = AppConfig.brainCLIPath
        syncScriptPath = AppConfig.syncScriptPath
        syncLogPath = AppConfig.syncLogPath
    }

    func resetIntegrationDefaults() {
        workspacePath = AppConfig.Defaults.workspacePath
        missionURLString = AppConfig.Defaults.missionURLString
        missionSSHHost = AppConfig.Defaults.missionSSHHost
        brainCLIPath = AppConfig.Defaults.brainCLIPath(workspace: workspacePath)
        syncScriptPath = AppConfig.Defaults.syncScriptPath(workspace: workspacePath)
        syncLogPath = AppConfig.Defaults.syncLogPath
    }
}

enum HealthState: String {
    case good = "Ready"
    case warn = "Attention"
    case off = "Off"
    case busy = "Running"

    var color: Color {
        switch self {
        case .good: return Color(red: 0.14, green: 0.56, blue: 0.38)
        case .warn: return Color(red: 0.78, green: 0.45, blue: 0.12)
        case .off: return Color(red: 0.42, green: 0.44, blue: 0.48)
        case .busy: return Color(red: 0.18, green: 0.38, blue: 0.76)
        }
    }
}

struct HealthCard: Identifiable {
    let id = UUID()
    let title: String
    let state: HealthState
    let value: String
    let detail: String
    let symbol: String
}

struct SetupStep: Identifiable {
    let id: String
    let title: String
    let detail: String
    let state: HealthState
    let action: String
    let symbol: String
}

struct BrainSource: Identifiable {
    let id: String
    let name: String
    let status: String
    let detail: String
    let mode: String
    let permission: String
    let location: String
    let metrics: [SourceMetric]
    let symbol: String
    let state: HealthState
    let isSensitive: Bool
}

struct SourceMetric: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let detail: String
    let symbol: String
}

struct BriefingItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let symbol: String
}

struct DailyCommandItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let priority: String
    let action: String
    let project: String
    let symbol: String
    let state: HealthState
    let query: String
}

struct RadarItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let reason: String
    let action: String
    let project: String
    let urgency: String
    let symbol: String
    let state: HealthState
    let query: String
    let path: String?
}

struct BrainFeedItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let detail: String
    let kind: FeedKind
    let symbol: String
    let state: HealthState
    let timestamp: Date
    let path: String?
}

struct OracleItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let kind: OracleKind
    let source: String
    let confidence: String
    let symbol: String
    let path: String?
}

struct OracleCommit: Identifiable {
    let id: String
    let title: String
    let question: String
    let preview: String
    let status: OracleCommitStatus
    let project: String
    let source: String
    let created: Date
    let path: String
    let tags: [String]
}

struct ProjectMemory: Identifiable {
    let id: String
    let name: String
    let summary: String
    let recommendedAction: String
    let contextPacks: [BrainFeedItem]
    let oracleCommits: [OracleCommit]
    let openLoops: [OracleItem]
    let decisions: [OracleItem]
    let lastActivity: Date
    let symbol: String
    let accent: Color

    var signalCount: Int {
        contextPacks.count + oracleCommits.count + openLoops.count + decisions.count
    }

    var delegatedCount: Int {
        oracleCommits.filter { $0.status == .delegated }.count
    }
}

enum OracleCommitStatus: String, CaseIterable, Identifiable {
    case new
    case accepted
    case linked
    case delegated
    case dismissed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .new: return "New"
        case .accepted: return "Accepted"
        case .linked: return "Linked"
        case .delegated: return "Delegated"
        case .dismissed: return "Dismissed"
        }
    }

    var symbol: String {
        switch self {
        case .new: return "tray.fill"
        case .accepted: return "checkmark.seal.fill"
        case .linked: return "link.circle.fill"
        case .delegated: return "paperplane.fill"
        case .dismissed: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .new: return .cyan
        case .accepted: return .green
        case .linked: return .mint
        case .delegated: return .orange
        case .dismissed: return .gray
        }
    }
}

enum OracleKind: String, CaseIterable, Identifiable {
    case bubbling
    case idea
    case openLoop
    case decision
    case opportunity

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bubbling: return "Bubbling Up"
        case .idea: return "Idea"
        case .openLoop: return "Open Loop"
        case .decision: return "Decision"
        case .opportunity: return "Opportunity"
        }
    }
}

enum FeedKind: String, CaseIterable, Identifiable {
    case all
    case context
    case sync
    case memory
    case alerts

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .context: return "Context"
        case .sync: return "Sync"
        case .memory: return "Memory"
        case .alerts: return "Alerts"
        }
    }
}

struct CommandResult {
    let stdout: String
    let stderr: String
    let status: Int32

    var succeeded: Bool {
        status == 0
    }
}

struct Paths {
    static var home: String { AppConfig.home }
    static var workspace: String { AppConfig.workspacePath }
    static var edgeExporter: String { "\(workspace)/Software/edge-brain-exporter" }
    static var syncScript: String { AppConfig.syncScriptPath }
    static var syncLog: String { AppConfig.syncLogPath }
    static var codexConfig: String { "\(home)/.codex/config.toml" }
    static var workspaceMCP: String { "\(workspace)/.mcp.json" }
    static var statsJSON: String { "\(workspace)/.brain/stats.json" }
    static var agentHistoryStatsJSON: String { "\(workspace)/.brain/agent-history-stats.json" }
    static var edgeSyncStateJSON: String { "\(workspace)/.brain/edge-brain-sync-state.json" }
    static var contextPacks: String { "\(workspace)/.brain/context-packs" }
    static var oracleInbox: String { "\(workspace)/Oracle Inbox" }
    static var brainCLI: String { AppConfig.brainCLIPath }
    static var missionSSHHost: String { AppConfig.missionSSHHost }
    static var missionURL: URL { URL(string: AppConfig.missionURLString) ?? URL(string: AppConfig.Defaults.missionURLString)! }
}

enum AppConfig {
    enum Keys {
        static let workspacePath = "terminalBrainWorkspacePath"
        static let missionURLString = "terminalBrainMissionURLString"
        static let missionSSHHost = "terminalBrainMissionSSHHost"
        static let brainCLIPath = "terminalBrainBrainCLIPath"
        static let syncScriptPath = "terminalBrainSyncScriptPath"
        static let syncLogPath = "terminalBrainSyncLogPath"
    }

    enum Environment {
        static let workspacePath = "TERMINAL_BRAIN_WORKSPACE"
        static let missionURLString = "TERMINAL_BRAIN_MISSION_URL"
        static let missionSSHHost = "TERMINAL_BRAIN_MISSION_SSH_HOST"
        static let brainCLIPath = "TERMINAL_BRAIN_CLI"
        static let syncScriptPath = "TERMINAL_BRAIN_SYNC_SCRIPT"
        static let syncLogPath = "TERMINAL_BRAIN_SYNC_LOG"
    }

    enum Defaults {
        static let home = FileManager.default.homeDirectoryForCurrentUser.path
        static let workspacePath = "\(home)/mejohnwc"
        static let missionURLString = "http://127.0.0.1:8080"
        static let missionSSHHost = ""
        static let syncLogPath = "\(home)/Library/Logs/franklin-edge-brain-sync.log"

        static func brainCLIPath(workspace: String) -> String {
            "\(workspace)/Software/brain-kernel/bin/brain.mjs"
        }

        static func syncScriptPath(workspace: String) -> String {
            "\(workspace)/Software/edge-brain-exporter/bin/run-edge-brain-sync.zsh"
        }
    }

    static var home: String { Defaults.home }

    static var workspacePath: String {
        configuredValue(env: Environment.workspacePath, key: Keys.workspacePath, fallback: Defaults.workspacePath)
    }

    static var missionURLString: String {
        configuredValue(env: Environment.missionURLString, key: Keys.missionURLString, fallback: Defaults.missionURLString)
    }

    static var missionSSHHost: String {
        configuredValue(env: Environment.missionSSHHost, key: Keys.missionSSHHost, fallback: Defaults.missionSSHHost)
    }

    static var brainCLIPath: String {
        configuredValue(env: Environment.brainCLIPath, key: Keys.brainCLIPath, fallback: Defaults.brainCLIPath(workspace: workspacePath))
    }

    static var syncScriptPath: String {
        configuredValue(env: Environment.syncScriptPath, key: Keys.syncScriptPath, fallback: Defaults.syncScriptPath(workspace: workspacePath))
    }

    static var syncLogPath: String {
        configuredValue(env: Environment.syncLogPath, key: Keys.syncLogPath, fallback: Defaults.syncLogPath)
    }

    private static func configuredValue(env: String, key: String, fallback: String) -> String {
        if let value = ProcessInfo.processInfo.environment[env]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
            return value
        }
        if let value = UserDefaults.standard.string(forKey: key)?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
            return value
        }
        return fallback
    }
}
