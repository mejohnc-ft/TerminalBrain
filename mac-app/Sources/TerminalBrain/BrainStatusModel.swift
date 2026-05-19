import AppKit
import Foundation
import SwiftUI

@MainActor
final class BrainStatusModel: ObservableObject {
    @Published var cards: [HealthCard] = []
    @Published var sources: [BrainSource] = []
    @Published var briefing: [BriefingItem] = []
    @Published var feedItems: [BrainFeedItem] = []
    @Published var oracleBrief: [String] = []
    @Published var oracleItems: [OracleItem] = []
    @Published var oracleQuestion = "What am I missing?"
    @Published var oracleAnswer = ""
    @Published var oracleMode = "local"
    @Published var oracleCommitOutput = ""
    @Published var oracleCommits: [OracleCommit] = []
    @Published var projects: [ProjectMemory] = []
    @Published var findings: [String] = []
    @Published var lastRefresh: Date?
    @Published var isRefreshing = false
    @Published var isSyncing = false
    @Published var isBuildingContextPack = false
    @Published var syncOutput = ""
    @Published var workQuery = "mission control brain"
    @Published var latestContextPackPath = ""
    @Published var startWorkOutput = ""
    @Published var appleNotesEnabledForManualSync: Bool {
        didSet {
            UserDefaults.standard.set(appleNotesEnabledForManualSync, forKey: "appleNotesEnabledForManualSync")
        }
    }
    @Published var appleNotesPermissionMessage = "Not checked in this app."
    private let controlServer = LocalControlServer()

    var summaryLine: String {
        if isSyncing { return "Sync running" }
        let warnings = cards.filter { $0.state == .warn }.count
        if warnings == 0 && !cards.isEmpty { return "Brain status ready" }
        return "\(warnings) item\(warnings == 1 ? "" : "s") need attention"
    }

    init() {
        appleNotesEnabledForManualSync = UserDefaults.standard.bool(forKey: "appleNotesEnabledForManualSync")
    }

    func startControlAPI() {
        controlServer.start()
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        async let processSnapshot = processCards()
        async let configSnapshot = configCards()
        async let indexSnapshot = indexCards()
        async let missionSnapshot = missionCards()

        let sections = await [processSnapshot, configSnapshot, indexSnapshot, missionSnapshot].flatMap { $0 }
        let builtSources = buildSources(from: sections)
        let builtBriefing = buildBriefing(from: sections)
        let builtFeed = buildFeedItems(from: sections)
        let builtOracleItems = buildOracleItems(from: sections, feedItems: builtFeed)
        let builtOracleCommits = loadOracleCommits()
        let builtProjects = buildProjectMemories(feedItems: builtFeed, oracleItems: builtOracleItems, oracleCommits: builtOracleCommits)
        cards = sections
        sources = builtSources
        briefing = builtBriefing
        feedItems = builtFeed
        oracleItems = builtOracleItems
        oracleCommits = builtOracleCommits
        projects = builtProjects
        oracleBrief = buildOracleBrief(from: sections, feedItems: builtFeed, oracleItems: builtOracleItems)
        if oracleAnswer.isEmpty {
            oracleAnswer = answerOracleQuestion("What am I missing?", items: builtOracleItems, cards: sections)
        }
        findings = buildFindings(from: sections)
        lastRefresh = Date()
    }

    func runSyncNow() async {
        guard !isSyncing else { return }
        isSyncing = true
        syncOutput = "Starting sync..."
        let result = await CommandRunner.run(
            "/bin/zsh",
            [Paths.syncScript],
            environment: ["EDGE_BRAIN_INCLUDE_APPLE_NOTES": appleNotesEnabledForManualSync ? "1" : "0"]
        )
        let combined = [result.stdout, result.stderr].filter { !$0.isEmpty }.joined(separator: "\n")
        syncOutput = combined.isEmpty ? "Sync finished with status \(result.status)." : combined
        isSyncing = false
        await refresh()
    }

    func startWork() async {
        let query = workQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !isBuildingContextPack else { return }
        isBuildingContextPack = true
        startWorkOutput = "Building context pack for \"\(query)\"..."
        let result = await CommandRunner.run("/usr/bin/env", ["node", Paths.brainCLI, "context-pack-save", query, Paths.workspace])
        let combined = [result.stdout, result.stderr].filter { !$0.isEmpty }.joined(separator: "\n")
        startWorkOutput = combined.isEmpty ? "Context pack command finished with status \(result.status)." : combined
        latestContextPackPath = newestContextPackPath()
        isBuildingContextPack = false
        await refresh()
    }

    func openLatestContextPack() {
        let path = latestContextPackPath.isEmpty ? newestContextPackPath() : latestContextPackPath
        guard !path.isEmpty else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    func openMissionControl() {
        NSWorkspace.shared.open(Paths.missionURL)
    }

    func openLogs() {
        NSWorkspace.shared.open(URL(fileURLWithPath: Paths.syncLog))
    }

    func openWorkspace() {
        NSWorkspace.shared.open(URL(fileURLWithPath: Paths.workspace))
    }

    func openPath(_ path: String) {
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    func checkAppleNotesPermission() {
        let script = """
        tell application "Notes"
            set noteCount to count of notes
            return "Notes reachable: " & noteCount & " notes"
        end tell
        """
        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        let result = appleScript?.executeAndReturnError(&error)
        if let error {
            appleNotesPermissionMessage = "Denied or unavailable: \(error)"
        } else {
            appleNotesPermissionMessage = result?.stringValue ?? "Notes reachable."
        }
    }

    func askOracle() async {
        let question = oracleQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        guard let url = URL(string: "http://127.0.0.1:8765/oracle/ask") else {
            oracleAnswer = answerOracleQuestion(question, items: oracleItems, cards: cards)
            return
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["question": question])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let answer = json["answer"] as? String else {
                oracleMode = "local"
                oracleAnswer = answerOracleQuestion(question, items: oracleItems, cards: cards)
                return
            }
            oracleMode = (json["mode"] as? String ?? "local").replacingOccurrences(of: "-", with: " ")
            oracleAnswer = answer
        } catch {
            oracleMode = "local"
            oracleAnswer = answerOracleQuestion(question, items: oracleItems, cards: cards)
        }
    }

    func commitOracleAnswer() async {
        let content = oracleAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        guard let url = URL(string: "http://127.0.0.1:8765/oracle/commit") else { return }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "title": "Oracle - \(oracleQuestion.trimmingCharacters(in: .whitespacesAndNewlines))",
                "question": oracleQuestion,
                "content": content,
                "source": "Terminal Brain.app",
                "tags": ["terminal-brain", "oracle", oracleMode]
            ])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["ok"] as? Bool == true,
                  let path = json["path"] as? String else {
                oracleCommitOutput = "Commit failed."
                return
            }
            oracleCommitOutput = "Committed to \(path)"
            oracleCommits = loadOracleCommits()
            projects = buildProjectMemories(feedItems: feedItems, oracleItems: oracleItems, oracleCommits: oracleCommits)
        } catch {
            oracleCommitOutput = "Commit failed: \(error.localizedDescription)"
        }
    }

    func setOracleCommitStatus(_ commit: OracleCommit, status: OracleCommitStatus) {
        let url = URL(fileURLWithPath: commit.path)
        guard var text = try? String(contentsOf: url, encoding: .utf8) else { return }
        if text.hasPrefix("---\n"), let end = text.range(of: "\n---\n", range: text.index(text.startIndex, offsetBy: 4)..<text.endIndex) {
            var frontmatter = String(text[..<end.lowerBound])
            let remainder = String(text[end.upperBound...])
            let lines = frontmatter.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            var replaced = false
            let nextLines = lines.map { line -> String in
                if line.hasPrefix("reviewStatus:") {
                    replaced = true
                    return "reviewStatus: \(status.rawValue)"
                }
                return line
            }
            frontmatter = nextLines.joined(separator: "\n")
            if !replaced {
                frontmatter += "\nreviewStatus: \(status.rawValue)"
            }
            text = "\(frontmatter)\n---\n\(remainder)"
        } else {
            text = """
            ---
            reviewStatus: \(status.rawValue)
            ---

            \(text)
            """
        }
        try? text.write(to: url, atomically: true, encoding: .utf8)
        oracleCommits = loadOracleCommits()
        projects = buildProjectMemories(feedItems: feedItems, oracleItems: oracleItems, oracleCommits: oracleCommits)
    }

    func openOracleInbox() {
        NSWorkspace.shared.open(URL(fileURLWithPath: Paths.oracleInbox))
    }

    func promoteOracleItem(_ item: OracleItem) {
        let safeTitle = item.title
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .prefix(8)
            .joined(separator: "-")
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let fileName = "\(timestamp)-\(safeTitle.isEmpty ? "oracle-item" : safeTitle).md"
        let path = Paths.oracleInbox
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        let body = """
        # \(item.title)

        Kind: \(item.kind.label)
        Source: \(item.source)
        Confidence: \(item.confidence)

        \(item.detail)

        Promoted by Terminal Brain Oracle on \(Date().formatted(date: .abbreviated, time: .shortened)).
        """
        try? body.write(toFile: "\(path)/\(fileName)", atomically: true, encoding: .utf8)
        NSWorkspace.shared.open(URL(fileURLWithPath: "\(path)/\(fileName)"))
        oracleCommits = loadOracleCommits()
        projects = buildProjectMemories(feedItems: feedItems, oracleItems: oracleItems, oracleCommits: oracleCommits)
    }

    private func processCards() async -> [HealthCard] {
        async let localBrain = pgrep("brain-kernel/server.mjs")
        async let appleNotesMCP = pgrep("apple-notes-mcp/server.mjs")
        async let draftsMCP = pgrep("drafts-obsidian-mcp/server.mjs")
        async let launchAgent = launchAgentStatus()

        let brain = await localBrain
        let notes = await appleNotesMCP
        let drafts = await draftsMCP
        let launchd = await launchAgent

        return [
            HealthCard(
                title: "Local Brain MCP",
                state: brain.isEmpty ? .warn : .good,
                value: brain.isEmpty ? "not running" : "running",
                detail: brain.isEmpty ? "Agents can still use config, but no active local-brain process was detected." : firstLine(brain),
                symbol: "server.rack"
            ),
            HealthCard(
                title: "Apple Notes MCP",
                state: notes.isEmpty ? .off : .warn,
                value: notes.isEmpty ? "manual only" : "running",
                detail: notes.isEmpty ? "No loose Node Apple Notes bridge is active." : firstLine(notes),
                symbol: "note.text"
            ),
            HealthCard(
                title: "Drafts MCP",
                state: drafts.isEmpty ? .off : .warn,
                value: drafts.isEmpty ? "manual only" : "running",
                detail: drafts.isEmpty ? "No loose Node Drafts bridge is active." : firstLine(drafts),
                symbol: "square.and.pencil"
            ),
            HealthCard(
                title: "Hourly Sync Agent",
                state: launchd.contains("Could not find service") ? .off : .warn,
                value: launchd.contains("Could not find service") ? "unloaded" : "loaded",
                detail: launchd.contains("Could not find service") ? "No background sync will trigger prompts." : "LaunchAgent is loaded. Review before enabling automatic sync.",
                symbol: "clock.arrow.circlepath"
            )
        ]
    }

    private func configCards() async -> [HealthCard] {
        let codex = CommandRunner.readText(Paths.codexConfig)
        let workspace = CommandRunner.readText(Paths.workspaceMCP)
        let codexLocalBrain = codex.contains("[mcp_servers.local-brain]")
        let workspaceLocalBrain = workspace.contains("local-brain")
        let codexNotes = codex.contains("[mcp_servers.apple-notes]")
        let workspaceNotes = workspace.contains("apple-notes")
        let codexDrafts = codex.contains("[mcp_servers.drafts-obsidian]")
        let workspaceDrafts = workspace.contains("drafts-obsidian")

        return [
            HealthCard(
                title: "Codex MCP Config",
                state: codexLocalBrain && !codexNotes && !codexDrafts ? .good : .warn,
                value: codexLocalBrain ? "local brain only" : "missing local brain",
                detail: "Apple Notes auto-start: \(codexNotes ? "on" : "off"). Drafts auto-start: \(codexDrafts ? "on" : "off").",
                symbol: "terminal"
            ),
            HealthCard(
                title: "Workspace MCP Config",
                state: workspaceLocalBrain && !workspaceNotes && !workspaceDrafts ? .good : .warn,
                value: workspaceLocalBrain ? "local brain only" : "missing local brain",
                detail: "Apple Notes auto-start: \(workspaceNotes ? "on" : "off"). Drafts auto-start: \(workspaceDrafts ? "on" : "off").",
                symbol: "folder.badge.gearshape"
            )
        ]
    }

    private func indexCards() async -> [HealthCard] {
        let stats = CommandRunner.readJSON(Paths.statsJSON)
        let agent = CommandRunner.readJSON(Paths.agentHistoryStatsJSON)
        let sync = CommandRunner.readJSON(Paths.edgeSyncStateJSON)
        let notes = stats["notes"] as? Int ?? 0
        let entities = stats["entities"] as? Int ?? 0
        let sessions = agent["sessions"] as? Int ?? 0
        let records = agent["records"] as? Int ?? 0
        let syncedRecords = sync["records"] as? [String: Any]
        let exported = sync["exported"] as? Int ?? sync["recordCount"] as? Int ?? syncedRecords?.count ?? 0
        let syncedAt = sync["syncedAt"] as? String ?? sync["updatedAt"] as? String ?? sync["generatedAt"] as? String ?? "unknown"

        return [
            HealthCard(
                title: "Obsidian Index",
                state: notes > 0 ? .good : .warn,
                value: "\(notes) notes",
                detail: "\(entities) entities in the derived local graph.",
                symbol: "doc.text.magnifyingglass"
            ),
            HealthCard(
                title: "Agent Histories",
                state: records > 0 ? .good : .warn,
                value: "\(records) records",
                detail: "\(sessions) Codex/Claude sessions summarized into derived memory.",
                symbol: "bubble.left.and.text.bubble.right"
            ),
            HealthCard(
                title: "Edge Sync State",
                state: exported > 0 ? .good : .warn,
                value: exported > 0 ? "\(exported) records" : "no state",
                detail: "Last known sync: \(syncedAt).",
                symbol: "arrow.triangle.2.circlepath"
            )
        ]
    }

    private func missionCards() async -> [HealthCard] {
        guard let brain = await missionJSON(path: "/api/brain") else {
            return [
                HealthCard(
                    title: "Mission Control",
                    state: .warn,
                    value: "offline",
                    detail: "Could not reach \(Paths.missionURL.absoluteString).",
                    symbol: "network.slash"
                )
            ]
        }

        let points = brain["total_points"] as? Int ?? brain["points"] as? Int ?? 0
        let collections = brain["collections"] as? [String: Any]
        let collectionText: String
        if let collections {
            collectionText = collections.keys.sorted().joined(separator: ", ")
        } else {
            collectionText = "brain API reachable"
        }

        return [
            HealthCard(
                title: "Mission Control",
                state: .good,
                value: points > 0 ? "\(points) points" : "reachable",
                detail: collectionText,
                symbol: "display"
            )
        ]
    }

    private func buildSources(from cards: [HealthCard]) -> [BrainSource] {
        func card(_ title: String) -> HealthCard? {
            cards.first { $0.title == title }
        }
        let stats = CommandRunner.readJSON(Paths.statsJSON)
        let agent = CommandRunner.readJSON(Paths.agentHistoryStatsJSON)
        let sync = CommandRunner.readJSON(Paths.edgeSyncStateJSON)
        let notes = stats["notes"] as? Int ?? 0
        let entities = stats["entities"] as? Int ?? 0
        let sessions = agent["sessions"] as? Int ?? 0
        let records = agent["records"] as? Int ?? 0
        let syncedRecords = sync["records"] as? [String: Any]
        let exported = sync["exported"] as? Int ?? sync["recordCount"] as? Int ?? syncedRecords?.count ?? 0
        let syncedAt = sync["syncedAt"] as? String ?? sync["updatedAt"] as? String ?? sync["generatedAt"] as? String ?? "unknown"
        let contextPackCount = contextPackCount()

        return [
            BrainSource(
                id: "obsidian",
                name: "Obsidian Vault",
                status: card("Obsidian Index")?.value ?? "unknown",
                detail: "Durable source of truth. Indexed locally and synced to Mission Control.",
                mode: "Indexed local vault",
                permission: "Filesystem read",
                location: Paths.workspace,
                metrics: [
                    SourceMetric(label: "Notes", value: "\(notes)", detail: "Indexed Markdown notes", symbol: "doc.text"),
                    SourceMetric(label: "Entities", value: "\(entities)", detail: "Derived graph entities", symbol: "point.3.connected.trianglepath.dotted"),
                    SourceMetric(label: "Packs", value: "\(contextPackCount)", detail: "Start Work context packs", symbol: "shippingbox")
                ],
                symbol: "doc.text.magnifyingglass",
                state: card("Obsidian Index")?.state ?? .warn,
                isSensitive: false
            ),
            BrainSource(
                id: "agent-history",
                name: "Codex / Claude Histories",
                status: card("Agent Histories")?.value ?? "unknown",
                detail: "Derived work memory from prior agent sessions; raw transcripts stay out of normal search.",
                mode: "Derived memory",
                permission: "Local index read",
                location: Paths.agentHistoryStatsJSON,
                metrics: [
                    SourceMetric(label: "Records", value: "\(records)", detail: "Derived agent-memory records", symbol: "list.bullet.rectangle"),
                    SourceMetric(label: "Sessions", value: "\(sessions)", detail: "Codex and Claude work sessions", symbol: "bubble.left.and.text.bubble.right"),
                    SourceMetric(label: "Raw", value: "Guarded", detail: "Raw transcripts are not normal search input", symbol: "lock.shield")
                ],
                symbol: "bubble.left.and.text.bubble.right",
                state: card("Agent Histories")?.state ?? .warn,
                isSensitive: true
            ),
            BrainSource(
                id: "drafts",
                name: "Drafts",
                status: card("Drafts MCP")?.value ?? "unknown",
                detail: "Fast capture source. Live MCP bridge remains manual to avoid background prompts.",
                mode: "Manual bridge",
                permission: "Explicit user action",
                location: "Drafts.app URL/action bridge",
                metrics: [
                    SourceMetric(label: "Bridge", value: card("Drafts MCP")?.value ?? "manual", detail: "No auto-start bridge by default", symbol: "switch.2"),
                    SourceMetric(label: "Sync", value: "\(exported)", detail: "Records in edge sync state", symbol: "arrow.triangle.2.circlepath"),
                    SourceMetric(label: "Policy", value: "Manual", detail: "Capture stays deliberate", symbol: "hand.raised")
                ],
                symbol: "square.and.pencil",
                state: card("Drafts MCP")?.state ?? .off,
                isSensitive: true
            ),
            BrainSource(
                id: "apple-notes",
                name: "Apple Notes",
                status: appleNotesEnabledForManualSync ? "manual sync enabled" : "manual sync off",
                detail: "Startup never reads Notes. Explicit permission check or manual sync can use this app identity.",
                mode: "Explicit only",
                permission: appleNotesEnabledForManualSync ? "Manual sync opt-in" : "No startup access",
                location: "Notes.app via Terminal Brain.app",
                metrics: [
                    SourceMetric(label: "Startup", value: "Off", detail: "No Notes read during app launch", symbol: "power"),
                    SourceMetric(label: "Prompt", value: "Owned", detail: "Permission belongs to Terminal Brain.app", symbol: "person.badge.shield.checkmark"),
                    SourceMetric(label: "Manual", value: appleNotesEnabledForManualSync ? "On" : "Off", detail: "Run Sync opt-in switch", symbol: "checklist")
                ],
                symbol: "note.text",
                state: appleNotesEnabledForManualSync ? .warn : .off,
                isSensitive: true
            ),
            BrainSource(
                id: "mission",
                name: "Mission Control",
                status: card("Mission Control")?.value ?? "unknown",
                detail: "Remote AI server, vector search, Qdrant, and heavier synthesis workflows.",
                mode: "Remote compute",
                permission: "SSH and local API",
                location: Paths.missionURL.absoluteString,
                metrics: [
                    SourceMetric(label: "Points", value: card("Mission Control")?.value ?? "unknown", detail: "Remote brain index", symbol: "display"),
                    SourceMetric(label: "Sync", value: "\(exported)", detail: "Last export record count", symbol: "arrow.up.arrow.down"),
                    SourceMetric(label: "Updated", value: shortDateLabel(syncedAt), detail: syncedAt, symbol: "clock")
                ],
                symbol: "display",
                state: card("Mission Control")?.state ?? .warn,
                isSensitive: false
            )
        ]
    }

    private func buildBriefing(from cards: [HealthCard]) -> [BriefingItem] {
        let stats = CommandRunner.readJSON(Paths.statsJSON)
        let agent = CommandRunner.readJSON(Paths.agentHistoryStatsJSON)
        let sync = CommandRunner.readJSON(Paths.edgeSyncStateJSON)
        let notes = stats["notes"] as? Int ?? 0
        let entities = stats["entities"] as? Int ?? 0
        let records = agent["records"] as? Int ?? 0
        let sessions = agent["sessions"] as? Int ?? 0
        let syncedRecords = sync["records"] as? [String: Any]
        let exported = sync["exported"] as? Int ?? sync["recordCount"] as? Int ?? syncedRecords?.count ?? 0
        let mission = cards.first { $0.title == "Mission Control" }
        let recent = recentMarkdownFiles(limit: 5)

        var items: [BriefingItem] = [
            BriefingItem(
                title: "Brain Coverage",
                detail: "\(notes) Obsidian notes, \(entities) extracted entities, \(records) derived agent-memory records.",
                symbol: "brain.head.profile"
            ),
            BriefingItem(
                title: "Agent Work Memory",
                detail: "\(sessions) Codex/Claude sessions are represented. This is the strongest source for continuity between coding sessions.",
                symbol: "terminal"
            ),
            BriefingItem(
                title: "Edge Sync",
                detail: exported > 0 ? "\(exported) records are tracked for remote sync." : "No sync state found yet. Run Sync will refresh the edge memory export.",
                symbol: "arrow.triangle.2.circlepath"
            ),
            BriefingItem(
                title: "Mission Control",
                detail: mission?.state == .good ? "Remote brain is reachable with \(mission?.value ?? "available") indexed." : "Remote brain is not reachable from this Mac right now.",
                symbol: "display"
            )
        ]

        if !recent.isEmpty {
            items.append(
                BriefingItem(
                    title: "Recent Notes",
                    detail: recent.joined(separator: "  |  "),
                    symbol: "clock"
                )
            )
        }
        return items
    }

    private func buildFeedItems(from cards: [HealthCard]) -> [BrainFeedItem] {
        var items = recentContextPacks(limit: 8)

        let now = Date()
        for card in cards {
            guard card.state == .warn else { continue }
            items.append(
                BrainFeedItem(
                    id: "card-\(card.title)",
                    title: card.title,
                    subtitle: card.state.rawValue,
                    detail: card.detail,
                    kind: .alerts,
                    symbol: card.symbol,
                    state: card.state,
                    timestamp: now,
                    path: nil
                )
            )
        }

        let sync = CommandRunner.readJSON(Paths.edgeSyncStateJSON)
        let syncRecords = sync["records"] as? [String: Any]
        let exported = sync["exported"] as? Int ?? sync["recordCount"] as? Int ?? syncRecords?.count ?? 0
        let updatedAt = sync["updatedAt"] as? String ?? sync["syncedAt"] as? String ?? sync["generatedAt"] as? String ?? "unknown"
        items.append(
            BrainFeedItem(
                id: "sync-state",
                title: "Edge sync state",
                subtitle: exported > 0 ? "\(exported) records" : "No export",
                detail: "Last known sync: \(updatedAt).",
                kind: .sync,
                symbol: "arrow.triangle.2.circlepath",
                state: exported > 0 ? .good : .warn,
                timestamp: dateFromSyncString(updatedAt) ?? now,
                path: Paths.edgeSyncStateJSON
            )
        )

        let agent = CommandRunner.readJSON(Paths.agentHistoryStatsJSON)
        let records = agent["records"] as? Int ?? 0
        let sessions = agent["sessions"] as? Int ?? 0
        if records > 0 {
            items.append(
                BrainFeedItem(
                    id: "agent-history",
                    title: "Agent work memory",
                    subtitle: "\(sessions) sessions",
                    detail: "\(records) derived Codex/Claude history records are available for continuity.",
                    kind: .memory,
                    symbol: "bubble.left.and.text.bubble.right",
                    state: .good,
                    timestamp: fileModifiedDate(Paths.agentHistoryStatsJSON) ?? now,
                    path: Paths.agentHistoryStatsJSON
                )
            )
        }

        return items.sorted { $0.timestamp > $1.timestamp }
    }

    private func buildOracleBrief(from cards: [HealthCard], feedItems: [BrainFeedItem], oracleItems: [OracleItem]) -> [String] {
        let stats = CommandRunner.readJSON(Paths.statsJSON)
        let agent = CommandRunner.readJSON(Paths.agentHistoryStatsJSON)
        let notes = stats["notes"] as? Int ?? 0
        let entities = stats["entities"] as? Int ?? 0
        let records = agent["records"] as? Int ?? 0
        let warnings = cards.filter { $0.state == .warn }
        let latestContext = feedItems.first { $0.kind == .context }?.title ?? "no recent context pack"
        let topLoop = oracleItems.first { $0.kind == .openLoop }?.title
        let topIdea = oracleItems.first { $0.kind == .idea || $0.kind == .opportunity }?.title

        var brief: [String] = [
            "Your durable memory is broad enough to be useful now: \(notes) notes, \(entities) entities, and \(records) derived agent-memory records are in play.",
            "The freshest work signal is \(latestContext). Treat that as the default context unless you intentionally pivot.",
            warnings.isEmpty ? "Your local permission posture is quiet: no prompt-prone Apple Notes or Drafts bridge is auto-running." : "\(warnings.count) system item\(warnings.count == 1 ? "" : "s") need attention before trusting automatic workflows."
        ]
        if let topLoop {
            brief.append("The strongest open loop to resolve is: \(topLoop).")
        }
        if let topIdea {
            brief.append("The idea worth revisiting is: \(topIdea).")
        }
        return brief
    }

    private func buildOracleItems(from cards: [HealthCard], feedItems: [BrainFeedItem]) -> [OracleItem] {
        var items: [OracleItem] = []

        for card in cards where card.state == .warn {
            items.append(
                OracleItem(
                    id: "oracle-warning-\(card.title)",
                    title: card.title,
                    detail: card.detail,
                    kind: .openLoop,
                    source: "System health",
                    confidence: "High",
                    symbol: card.symbol,
                    path: nil
                )
            )
        }

        for feed in feedItems.prefix(6) where feed.kind == .context || feed.kind == .memory {
            items.append(
                OracleItem(
                    id: "oracle-feed-\(feed.id)",
                    title: feed.title,
                    detail: feed.detail,
                    kind: feed.kind == .memory ? .bubbling : .opportunity,
                    source: feed.subtitle,
                    confidence: feed.kind == .memory ? "Medium" : "High",
                    symbol: feed.symbol,
                    path: feed.path
                )
            )
        }

        items.append(contentsOf: extractedOracleItems(limit: 12))
        return dedupeOracleItems(items).prefix(16).map { $0 }
    }

    private func extractedOracleItems(limit: Int) -> [OracleItem] {
        let markers: [(OracleKind, String, String)] = [
            (.openLoop, "todo", "checklist"),
            (.openLoop, "next", "arrow.right.circle"),
            (.openLoop, "waiting", "hourglass"),
            (.openLoop, "blocked", "exclamationmark.octagon"),
            (.decision, "decision", "checkmark.seal"),
            (.decision, "decided", "checkmark.seal"),
            (.idea, "idea", "lightbulb"),
            (.idea, "maybe", "sparkle.magnifyingglass"),
            (.opportunity, "opportunity", "target"),
            (.bubbling, "should", "bubble.left.and.exclamationmark.bubble.right")
        ]

        var results: [OracleItem] = []
        for pack in recentContextPackDocuments(limit: 8) {
            let lines = pack.text
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") && !$0.hasPrefix("---") }

            for line in lines {
                let lowered = line.lowercased()
                guard let marker = markers.first(where: { lowered.contains($0.1) }) else { continue }
                let title = oracleTitle(from: line)
                results.append(
                    OracleItem(
                        id: "oracle-line-\(pack.url.lastPathComponent)-\(results.count)",
                        title: title,
                        detail: line.prefixString(maxLength: 260),
                        kind: marker.0,
                        source: pack.url.deletingPathExtension().lastPathComponent,
                        confidence: "Heuristic",
                        symbol: marker.2,
                        path: pack.url.path
                    )
                )
                if results.count >= limit {
                    return results
                }
            }
        }
        return results
    }

    private func answerOracleQuestion(_ question: String, items: [OracleItem], cards: [HealthCard]) -> String {
        let query = question.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let openLoops = items.filter { $0.kind == .openLoop }
        let ideas = items.filter { $0.kind == .idea || $0.kind == .opportunity }
        let warnings = cards.filter { $0.state == .warn }

        if query.contains("missing") || query.contains("not consider") {
            let loop = openLoops.first?.title ?? "no urgent open loop is visible"
            let idea = ideas.first?.title ?? "no strong dormant idea is visible"
            return "The thing you may not be considering is \(loop). The adjacent idea to revisit is \(idea). I would review the top Bubbling Up cards, then build a context pack before delegating any implementation work."
        }
        if query.contains("today") || query.contains("next") || query.contains("work") {
            let latest = feedItems.first { $0.kind == .context }?.title ?? "your latest context pack"
            return "Work from \(latest). Resolve \(openLoops.first?.title ?? "the highest open loop") first, then use Start Work to create a narrow handoff for agents."
        }
        if query.contains("idea") || query.contains("opportunity") {
            return ideas.prefix(3).map { "\($0.title): \($0.detail)" }.joined(separator: "\n\n").ifEmpty("I do not see a strong idea signal yet. Add more Drafts/Obsidian capture or build a context pack around the area you want explored.")
        }
        if query.contains("safe") || query.contains("permission") || query.contains("prompt") {
            return warnings.isEmpty ? "The system is prompt-safe right now: Apple Notes and Drafts bridges are not auto-running, and the hourly sync agent is unloaded." : warnings.map { "\($0.title): \($0.detail)" }.joined(separator: "\n")
        }
        return items.prefix(4).map { "\($0.kind.label): \($0.title). \($0.detail)" }.joined(separator: "\n\n")
    }

    private func pgrep(_ pattern: String) async -> String {
        let result = await CommandRunner.run("/usr/bin/pgrep", ["-fl", pattern])
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func launchAgentStatus() async -> String {
        let uid = getuid()
        let result = await CommandRunner.run("/bin/launchctl", ["print", "gui/\(uid)/com.franklin.edge-brain-sync"])
        return [result.stdout, result.stderr].joined(separator: "\n")
    }

    private func missionJSON(path: String) async -> [String: Any]? {
        guard var components = URLComponents(url: Paths.missionURL, resolvingAgainstBaseURL: false) else { return nil }
        components.path = path
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 4
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch {
            return nil
        }
    }

    private func buildFindings(from cards: [HealthCard]) -> [String] {
        var result: [String] = []
        if cards.contains(where: { $0.title == "Apple Notes MCP" && $0.state == .warn }) {
            result.append("Apple Notes MCP is running as a loose Node bridge. Stop it if macOS permission prompts return.")
        }
        if cards.contains(where: { $0.title == "Drafts MCP" && $0.state == .warn }) {
            result.append("Drafts MCP is running as a loose Node bridge. Keep it manual unless you intentionally need live Drafts agent access.")
        }
        if cards.contains(where: { $0.title == "Mission Control" && $0.state == .warn }) {
            result.append("Mission Control is unreachable from this Mac. Check the configured AI server or network route.")
        }
        if result.isEmpty {
            result.append("No prompt-prone Brain bridges are auto-running. Live source access remains deliberate.")
        }
        return result
    }

    private func firstLine(_ text: String) -> String {
        text.split(separator: "\n").first.map(String.init) ?? text
    }

    private func recentMarkdownFiles(limit: Int) -> [String] {
        let result = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: Paths.workspace),
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        var files: [(Date, String)] = []
        for url in result ?? [] {
            if url.pathExtension.lowercased() == "md",
               let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
               let modified = values.contentModificationDate {
                files.append((modified, url.lastPathComponent))
            }
        }
        return files.sorted { $0.0 > $1.0 }.prefix(limit).map { $0.1 }
    }

    private func newestContextPackPath() -> String {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: Paths.contextPacks),
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return ""
        }
        return urls
            .filter { $0.pathExtension.lowercased() == "md" }
            .compactMap { url -> (Date, URL)? in
                guard let modified = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else {
                    return nil
                }
                return (modified, url)
            }
            .sorted { $0.0 > $1.0 }
            .first?.1.path ?? ""
    }

    private func contextPackCount() -> Int {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: Paths.contextPacks),
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        return urls.filter { $0.pathExtension.lowercased() == "md" }.count
    }

    private func recentContextPacks(limit: Int) -> [BrainFeedItem] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: Paths.contextPacks),
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls
            .filter { $0.pathExtension.lowercased() == "md" }
            .compactMap { url -> (Date, BrainFeedItem)? in
                guard let modified = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else {
                    return nil
                }
                let title = contextPackTitle(from: url)
                let detail = contextPackPreview(from: url)
                return (
                    modified,
                    BrainFeedItem(
                        id: "context-\(url.lastPathComponent)",
                        title: title,
                        subtitle: "Context pack",
                        detail: detail,
                        kind: .context,
                        symbol: "shippingbox.fill",
                        state: .good,
                        timestamp: modified,
                        path: url.path
                    )
                )
            }
            .sorted { $0.0 > $1.0 }
            .prefix(limit)
            .map { $0.1 }
    }

    private func recentContextPackDocuments(limit: Int) -> [(url: URL, text: String)] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: Paths.contextPacks),
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls
            .filter { $0.pathExtension.lowercased() == "md" }
            .compactMap { url -> (Date, URL)? in
                guard let modified = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else {
                    return nil
                }
                return (modified, url)
            }
            .sorted { $0.0 > $1.0 }
            .prefix(limit)
            .compactMap { pair in
                let url = pair.1
                guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                    return nil
                }
                return (url, text)
            }
    }

    private func contextPackTitle(from url: URL) -> String {
        let base = url.deletingPathExtension().lastPathComponent
        let parts = base.split(separator: "-", omittingEmptySubsequences: true)
        let slug = parts.dropFirst(6).joined(separator: " ")
        if !slug.isEmpty {
            return slug.capitalized
        }
        return url.deletingPathExtension().lastPathComponent
    }

    private func contextPackPreview(from url: URL) -> String {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "Open this context pack for the full handoff."
        }
        let lines = text
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") && !$0.hasPrefix("---") }
        return lines.prefix(2).joined(separator: " ").prefixString(maxLength: 220)
    }

    private func oracleTitle(from line: String) -> String {
        var cleaned = line
            .replacingOccurrences(of: "- [ ]", with: "")
            .replacingOccurrences(of: "- [x]", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let colon = cleaned.firstIndex(of: ":"), cleaned.distance(from: cleaned.startIndex, to: colon) < 36 {
            cleaned = String(cleaned[cleaned.index(after: colon)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return cleaned.prefixString(maxLength: 72)
    }

    private func dedupeOracleItems(_ items: [OracleItem]) -> [OracleItem] {
        var seen = Set<String>()
        var output: [OracleItem] = []
        for item in items {
            let key = item.title.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            output.append(item)
        }
        return output
    }

    private func buildProjectMemories(feedItems: [BrainFeedItem], oracleItems: [OracleItem], oracleCommits: [OracleCommit]) -> [ProjectMemory] {
        var buckets: [String: (name: String, context: [BrainFeedItem], commits: [OracleCommit], loops: [OracleItem], decisions: [OracleItem])] = [:]

        func ensure(_ name: String) -> String {
            let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines).ifEmpty("General Brain")
            let id = projectID(from: cleanName)
            if buckets[id] == nil {
                buckets[id] = (cleanName, [], [], [], [])
            }
            return id
        }

        for feed in feedItems where feed.kind == .context {
            let id = ensure(projectName(from: "\(feed.title) \(feed.detail)"))
            buckets[id]?.context.append(feed)
        }

        for commit in oracleCommits {
            let id = ensure(projectName(from: "\(commit.title) \(commit.question) \(commit.preview) \(commit.tags.joined(separator: " "))"))
            buckets[id]?.commits.append(commit)
        }

        for item in oracleItems {
            let id = ensure(projectName(from: "\(item.title) \(item.detail) \(item.source)"))
            if item.kind == .openLoop {
                buckets[id]?.loops.append(item)
            }
            if item.kind == .decision {
                buckets[id]?.decisions.append(item)
            }
        }

        if buckets.isEmpty {
            _ = ensure("Terminal Brain")
        }

        return buckets.map { id, bucket in
            let lastActivity = maxDate(
                bucket.context.map(\.timestamp) +
                bucket.commits.map(\.created)
            ) ?? Date.distantPast
            let loops = bucket.loops.prefix(5).map { $0 }
            let decisions = bucket.decisions.prefix(5).map { $0 }
            let contextPacks = bucket.context.sorted { $0.timestamp > $1.timestamp }.prefix(6).map { $0 }
            let commits = bucket.commits.sorted { $0.created > $1.created }.prefix(8).map { $0 }
            let summary = projectSummary(
                name: bucket.name,
                contextCount: bucket.context.count,
                commitCount: bucket.commits.count,
                openLoopCount: bucket.loops.count,
                decisionCount: bucket.decisions.count
            )
            let recommendedAction = projectRecommendedAction(
                name: bucket.name,
                commits: bucket.commits,
                openLoops: bucket.loops,
                contextPacks: bucket.context
            )
            return ProjectMemory(
                id: id,
                name: bucket.name,
                summary: summary,
                recommendedAction: recommendedAction,
                contextPacks: contextPacks,
                oracleCommits: commits,
                openLoops: Array(loops),
                decisions: Array(decisions),
                lastActivity: lastActivity,
                symbol: projectSymbol(for: bucket.name),
                accent: projectAccent(for: bucket.name)
            )
        }
        .filter { $0.signalCount > 0 || $0.name == "Terminal Brain" }
        .sorted {
            if $0.signalCount == $1.signalCount {
                return $0.lastActivity > $1.lastActivity
            }
            return $0.signalCount > $1.signalCount
        }
    }

    private func projectName(from text: String) -> String {
        let lowered = text.lowercased()
        let known: [(needle: String, name: String)] = [
            ("terminal brain", "Terminal Brain"),
            ("mission control", "Mission Control"),
            ("centrexai", "centrexAI"),
            ("centrex ai", "centrexAI"),
            ("franklin", "Franklin Systems"),
            ("drafts", "Drafts"),
            ("apple notes", "Apple Notes"),
            ("obsidian", "Obsidian"),
            ("rewst", "Rewst"),
            ("mcp", "MCP Platform")
        ]
        if let match = known.first(where: { lowered.contains($0.needle) }) {
            return match.name
        }
        let words = lowered
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 }
            .filter { !["context", "pack", "oracle", "brain", "work", "with", "from", "local", "memory", "generated", "start"].contains($0) }
        return words.prefix(2).joined(separator: " ").capitalized.ifEmpty("General Brain")
    }

    private func projectID(from name: String) -> String {
        name.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
            .ifEmpty("general-brain")
    }

    private func projectSummary(name: String, contextCount: Int, commitCount: Int, openLoopCount: Int, decisionCount: Int) -> String {
        "\(contextCount) context pack\(contextCount == 1 ? "" : "s"), \(commitCount) committed read\(commitCount == 1 ? "" : "s"), \(openLoopCount) open loop\(openLoopCount == 1 ? "" : "s"), and \(decisionCount) decision signal\(decisionCount == 1 ? "" : "s") are attached to \(name)."
    }

    private func projectRecommendedAction(name: String, commits: [OracleCommit], openLoops: [OracleItem], contextPacks: [BrainFeedItem]) -> String {
        if let delegated = commits.first(where: { $0.status == .delegated }) {
            return "Turn delegated read into a Start Work pack: \(delegated.title)."
        }
        if let loop = openLoops.first {
            return "Resolve the highest open loop: \(loop.title)."
        }
        if let fresh = contextPacks.sorted(by: { $0.timestamp > $1.timestamp }).first {
            return "Use the freshest context pack as the working frame: \(fresh.title)."
        }
        if let unread = commits.first(where: { $0.status == .new }) {
            return "Review and classify the newest Oracle read: \(unread.title)."
        }
        return "Ask Oracle what changed for \(name), then commit the useful read."
    }

    private func projectSymbol(for name: String) -> String {
        let lowered = name.lowercased()
        if lowered.contains("terminal") { return "terminal.fill" }
        if lowered.contains("mission") { return "display" }
        if lowered.contains("centrex") { return "building.2.fill" }
        if lowered.contains("draft") { return "square.and.pencil" }
        if lowered.contains("notes") { return "note.text" }
        if lowered.contains("obsidian") { return "doc.text.magnifyingglass" }
        if lowered.contains("mcp") { return "antenna.radiowaves.left.and.right" }
        return "folder.fill"
    }

    private func projectAccent(for name: String) -> Color {
        let lowered = name.lowercased()
        if lowered.contains("terminal") { return .cyan }
        if lowered.contains("mission") { return .mint }
        if lowered.contains("centrex") { return .blue }
        if lowered.contains("draft") { return .purple }
        if lowered.contains("notes") { return .yellow }
        if lowered.contains("obsidian") { return .indigo }
        return .teal
    }

    private func maxDate(_ dates: [Date]) -> Date? {
        dates.max()
    }

    private func loadOracleCommits() -> [OracleCommit] {
        try? FileManager.default.createDirectory(atPath: Paths.oracleInbox, withIntermediateDirectories: true)
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: Paths.oracleInbox),
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls
            .filter { $0.pathExtension.lowercased() == "md" }
            .compactMap { url -> OracleCommit? in
                guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
                let parsed = parseOracleCommit(text)
                let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let created = parsed.created.flatMap { ISO8601DateFormatter().date(from: $0) } ?? modified
                let title = parsed.title.ifEmpty(url.deletingPathExtension().lastPathComponent)
                let status = OracleCommitStatus(rawValue: parsed.frontmatter["reviewStatus"] ?? parsed.frontmatter["status"] ?? "new") ?? .new
                let tags = parsed.tags.isEmpty ? ["oracle"] : parsed.tags
                return OracleCommit(
                    id: url.path,
                    title: title,
                    question: parsed.question,
                    preview: parsed.preview,
                    status: status,
                    source: parsed.frontmatter["source"] ?? "Oracle Inbox",
                    created: created,
                    path: url.path,
                    tags: tags
                )
            }
            .sorted { $0.created > $1.created }
    }

    private func parseOracleCommit(_ text: String) -> (frontmatter: [String: String], tags: [String], title: String, question: String, preview: String, created: String?) {
        var frontmatter: [String: String] = [:]
        var tags: [String] = []
        var body = text

        if text.hasPrefix("---\n"), let end = text.range(of: "\n---\n", range: text.index(text.startIndex, offsetBy: 4)..<text.endIndex) {
            let rawFrontmatter = String(text[text.index(text.startIndex, offsetBy: 4)..<end.lowerBound])
            body = String(text[end.upperBound...])
            var activeKey = ""
            for rawLine in rawFrontmatter.split(separator: "\n", omittingEmptySubsequences: false) {
                let line = String(rawLine)
                if line.trimmingCharacters(in: .whitespaces).hasPrefix("-"), activeKey == "tags" {
                    var tag = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if tag.hasPrefix("-") {
                        tag.removeFirst()
                    }
                    tag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !tag.isEmpty { tags.append(tag) }
                    continue
                }
                guard let colon = line.firstIndex(of: ":") else { continue }
                let key = String(line[..<colon]).trimmingCharacters(in: .whitespacesAndNewlines)
                let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                activeKey = key
                if key != "tags" {
                    frontmatter[key] = value
                }
            }
        }

        let lines = body
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        let title = lines.first { $0.hasPrefix("# ") }?
            .replacingOccurrences(of: "# ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let question = sectionText(named: "Question", in: lines).prefixString(maxLength: 240)
        let read = sectionText(named: "Read", in: lines)
        let previewSource = read.isEmpty ? lines.filter { !$0.isEmpty && !$0.hasPrefix("#") }.joined(separator: " ") : read
        return (
            frontmatter,
            tags,
            title,
            question,
            previewSource.prefixString(maxLength: 260),
            frontmatter["created"]
        )
    }

    private func sectionText(named section: String, in lines: [String]) -> String {
        guard let start = lines.firstIndex(where: { $0 == "## \(section)" }) else { return "" }
        var output: [String] = []
        for line in lines.dropFirst(start + 1) {
            if line.hasPrefix("## ") { break }
            if !line.isEmpty { output.append(line) }
        }
        return output.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fileModifiedDate(_ path: String) -> Date? {
        let url = URL(fileURLWithPath: path)
        return try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    private func dateFromSyncString(_ value: String) -> Date? {
        ISO8601DateFormatter().date(from: value)
    }

    private func shortDateLabel(_ value: String) -> String {
        guard let date = dateFromSyncString(value) else {
            return "Unknown"
        }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

private extension String {
    func prefixString(maxLength: Int) -> String {
        guard count > maxLength else { return self }
        return String(prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
