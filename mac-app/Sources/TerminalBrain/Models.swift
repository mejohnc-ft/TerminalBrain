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

    init() {
        let rawTheme = UserDefaults.standard.string(forKey: "terminalBrainTheme") ?? AppTheme.midnight.rawValue
        theme = AppTheme(rawValue: rawTheme) ?? .system
        reduceGlass = UserDefaults.standard.bool(forKey: "terminalBrainReduceGlass")
        showAdvancedSystem = UserDefaults.standard.bool(forKey: "terminalBrainShowAdvancedSystem")
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
    let source: String
    let created: Date
    let path: String
    let tags: [String]
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
    static let home = FileManager.default.homeDirectoryForCurrentUser.path
    static let workspace = "\(home)/mejohnwc"
    static let edgeExporter = "\(workspace)/Software/edge-brain-exporter"
    static let syncScript = "\(edgeExporter)/bin/run-edge-brain-sync.zsh"
    static let syncLog = "\(home)/Library/Logs/franklin-edge-brain-sync.log"
    static let codexConfig = "\(home)/.codex/config.toml"
    static let workspaceMCP = "\(workspace)/.mcp.json"
    static let statsJSON = "\(workspace)/.brain/stats.json"
    static let agentHistoryStatsJSON = "\(workspace)/.brain/agent-history-stats.json"
    static let edgeSyncStateJSON = "\(workspace)/.brain/edge-brain-sync-state.json"
    static let contextPacks = "\(workspace)/.brain/context-packs"
    static let oracleInbox = "\(workspace)/Oracle Inbox"
    static let brainCLI = "\(workspace)/Software/brain-kernel/bin/brain.mjs"
    static let missionSSHHost = "mejohnc@192.168.0.54"
    static let missionURL = URL(string: "http://192.168.0.54:8080")!
}
