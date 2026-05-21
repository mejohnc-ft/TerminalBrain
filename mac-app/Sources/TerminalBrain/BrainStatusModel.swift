import AppKit
import Foundation
import SwiftUI

@MainActor
final class BrainStatusModel: ObservableObject {
    @Published var cards: [HealthCard] = []
    @Published var sources: [BrainSource] = []
    @Published var briefing: [BriefingItem] = []
    @Published var setupSteps: [SetupStep] = []
    @Published var dailyCommands: [DailyCommandItem] = []
    @Published var operatorBrief: [OperatorBriefItem] = []
    @Published var radarItems: [RadarItem] = []
    @Published var feedItems: [BrainFeedItem] = []
    @Published var oracleBrief: [String] = []
    @Published var oracleItems: [OracleItem] = []
    @Published var oracleQuestion = "What am I missing?"
    @Published var oracleAnswer = ""
    @Published var oracleMode = "local"
    @Published var oracleSuggestedActions: [String] = []
    @Published var oracleCommitOutput = ""
    @Published var isAskingOracle = false
    @Published var blindspotAnswer = ""
    @Published var blindspotAnswerTitle = ""
    @Published var blindspotOutput = ""
    @Published var isAskingBlindspot = false
    @Published var ideaAnswer = ""
    @Published var ideaAnswerTitle = ""
    @Published var ideaOutput = ""
    @Published var isAskingIdea = false
    @Published var quickIdea = ""
    @Published var quickIdeaOutput = ""
    @Published var outcomeTitle = ""
    @Published var outcomeText = ""
    @Published var outcomeNextAction = ""
    @Published var outcomeOutput = ""
    @Published var useNowCopyOutput = ""
    @Published var firstMinuteCopyOutput = ""
    @Published var demoCopyOutput = ""
    @Published var playbookCopyOutput = ""
    @Published var valueAuditCopyOutput = ""
    @Published var completionAuditCopyOutput = ""
    @Published var nowCopyOutput = ""
    @Published var processMapCopyOutput = ""
    @Published var cleanupPlanCopyOutput = ""
    @Published var supportBundleCopyOutput = ""
    @Published var workBlockCopyOutput = ""
    @Published var valueProofCopyOutput = ""
    @Published var snapshotCopyOutput = ""
    @Published var startHereCopyOutput = ""
    @Published var valueBriefCopyOutput = ""
    @Published var oracleBriefCopyOutput = ""
    @Published var oracleDigestCopyOutput = ""
    @Published var briefCopyOutput = ""
    @Published var decisionLaneCopyOutput = ""
    @Published var blindspotCopyOutput = ""
    @Published var ideaPulseCopyOutput = ""
    @Published var projectMemoryCopyOutput = ""
    @Published var sourceInventoryCopyOutput = ""
    @Published var memoryBriefCopyOutput = ""
    @Published var memoryPromoteOutput = ""
    @Published var recentWorkPromoteOutput = ""
    @Published var deckCopyOutput = ""
    @Published var latestPackCopyOutput = ""
    @Published var handoffCopyOutput = ""
    @Published var agentPromptCopyOutput = ""
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

    var setupAttentionCount: Int {
        setupSteps.filter { $0.state == .warn }.count
    }

    var focusItem: FocusItem {
        buildFocusItem(radarItems: radarItems, dailyCommands: dailyCommands)
    }

    var blindspotItems: [BlindspotItem] {
        buildBlindspots(
            focus: focusItem,
            radarItems: radarItems,
            setupSteps: setupSteps,
            projects: projects,
            oracleItems: oracleItems,
            oracleCommits: oracleCommits
        )
    }

    var ideaPulseItems: [IdeaPulseItem] {
        buildIdeaPulse(
            oracleItems: oracleItems,
            oracleCommits: oracleCommits,
            projects: projects,
            feedItems: feedItems
        )
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
        let builtSetupSteps = buildSetupSteps(from: sections)
        let builtFeed = buildFeedItems(from: sections)
        let builtOracleItems = buildOracleItems(from: sections, feedItems: builtFeed)
        let builtOracleCommits = loadOracleCommits()
        let builtProjects = buildProjectMemories(feedItems: builtFeed, oracleItems: builtOracleItems, oracleCommits: builtOracleCommits)
        let builtRadarItems = buildRadarItems(cards: sections, setupSteps: builtSetupSteps, projects: builtProjects, oracleItems: builtOracleItems, oracleCommits: builtOracleCommits, feedItems: builtFeed)
        let builtDailyCommands = buildDailyCommands(cards: sections, projects: builtProjects, oracleCommits: builtOracleCommits, feedItems: builtFeed, radarItems: builtRadarItems)
        let builtFocusItem = buildFocusItem(radarItems: builtRadarItems, dailyCommands: builtDailyCommands)
        let builtOperatorBrief = buildOperatorBrief(cards: sections, focus: builtFocusItem, radarItems: builtRadarItems, projects: builtProjects, oracleCommits: builtOracleCommits, oracleItems: builtOracleItems, feedItems: builtFeed)
        cards = sections
        sources = builtSources
        briefing = builtBriefing
        setupSteps = builtSetupSteps
        dailyCommands = builtDailyCommands
        operatorBrief = builtOperatorBrief
        radarItems = builtRadarItems
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

    private func rebuildOperatorBrief() {
        operatorBrief = buildOperatorBrief(
            cards: cards,
            focus: focusItem,
            radarItems: radarItems,
            projects: projects,
            oracleCommits: oracleCommits,
            oracleItems: oracleItems,
            feedItems: feedItems
        )
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

    func copyLatestContextPack() async {
        guard let metadataURL = URL(string: "http://127.0.0.1:8765/context-packs/latest"),
              let markdownURL = URL(string: "http://127.0.0.1:8765/context-packs/latest/markdown") else { return }
        do {
            let (metadataData, _) = try await URLSession.shared.data(from: metadataURL)
            guard let metadata = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any],
                  metadata["ok"] as? Bool == true else {
                latestPackCopyOutput = "No context pack yet."
                return
            }
            let (data, _) = try await URLSession.shared.data(from: markdownURL)
            guard let markdown = String(data: data, encoding: .utf8), !markdown.isEmpty else {
                latestPackCopyOutput = "Latest pack copy failed."
                return
            }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(markdown, forType: .string)
            latestPackCopyOutput = "Latest pack copied."
        } catch {
            latestPackCopyOutput = "Latest pack copy failed: \(error.localizedDescription)"
        }
    }

    func copyHandoff() async {
        guard let url = URL(string: "http://127.0.0.1:8765/handoff/markdown") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let markdown = String(data: data, encoding: .utf8), !markdown.isEmpty else {
                handoffCopyOutput = "Handoff copy failed."
                return
            }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(markdown, forType: .string)
            handoffCopyOutput = "Handoff copied."
        } catch {
            handoffCopyOutput = "Handoff copy failed: \(error.localizedDescription)"
        }
    }

    func copyAgentPrompt() async {
        await copyMarkdown(path: "/agent-prompt/markdown", label: "Agent Prompt") { message in
            agentPromptCopyOutput = message
        }
    }

    func copyUseNow() async {
        await copyMarkdown(path: "/use-now/markdown", label: "Use Now") { message in
            useNowCopyOutput = message
        }
    }

    func copyFirstMinute() async {
        await copyMarkdown(path: "/first-minute/markdown", label: "First Minute") { message in
            firstMinuteCopyOutput = message
        }
    }

    func copyDemo() async {
        await copyMarkdown(path: "/demo/markdown", label: "Demo") { message in
            demoCopyOutput = message
        }
    }

    func copyPlaybook() async {
        await copyMarkdown(path: "/playbook/markdown", label: "Playbook") { message in
            playbookCopyOutput = message
        }
    }

    func copyValueAudit() async {
        await copyMarkdown(path: "/value-audit/markdown", label: "Value Audit") { message in
            valueAuditCopyOutput = message
        }
    }

    func copyCompletionAudit() async {
        await copyMarkdown(path: "/completion-audit/markdown", label: "Completion Audit") { message in
            completionAuditCopyOutput = message
        }
    }

    func copyNow() async {
        await copyMarkdown(path: "/now/markdown", label: "Now") { message in
            nowCopyOutput = message
        }
    }

    func copyProcessMap() async {
        await copyMarkdown(path: "/process-map/markdown", label: "Process Map") { message in
            processMapCopyOutput = message
        }
    }

    func copyCleanupPlan() async {
        await copyMarkdown(path: "/cleanup-plan/markdown", label: "Cleanup Plan") { message in
            cleanupPlanCopyOutput = message
        }
    }

    func copySupportBundle() async {
        await copyMarkdown(path: "/support-bundle/markdown", label: "Support Bundle") { message in
            supportBundleCopyOutput = message
        }
    }

    func copyWorkBlock() async {
        await copyMarkdown(path: "/work-block/markdown", label: "Work Block") { message in
            workBlockCopyOutput = message
        }
    }

    func copyValueProof() async {
        await copyMarkdown(path: "/value-proof/markdown", label: "Value Proof") { message in
            valueProofCopyOutput = message
        }
    }

    func copyOperatorBrief() async {
        await copyMarkdown(path: "/operator-brief/markdown", label: "Operator Brief") { message in
            briefCopyOutput = message
        }
    }

    func copyValueBrief() async {
        await copyMarkdown(path: "/value-brief/markdown", label: "Value Brief") { message in
            valueBriefCopyOutput = message
        }
    }

    func copyOracleBrief() async {
        await copyMarkdown(path: "/oracle/brief/markdown", label: "Oracle Brief") { message in
            oracleBriefCopyOutput = message
        }
    }

    func copyStartHere() async {
        await copyMarkdown(path: "/start-here/markdown", label: "Start Here") { message in
            startHereCopyOutput = message
        }
    }

    func copyOracleDigest() async {
        await copyMarkdown(path: "/oracle-digest/markdown", label: "Oracle Digest") { message in
            oracleDigestCopyOutput = message
        }
    }

    func copyDecisionLane() async {
        await copyMarkdown(path: "/today/markdown", label: "Decision Lane") { message in
            decisionLaneCopyOutput = message
        }
    }

    func copyBlindspotBrief() async {
        await copyMarkdown(path: "/blindspots/markdown", label: "Blindspot Brief") { message in
            blindspotCopyOutput = message
        }
    }

    func copyIdeaPulse() async {
        await copyMarkdown(path: "/ideas/markdown", label: "Idea Pulse") { message in
            ideaPulseCopyOutput = message
        }
    }

    func copyProjectMemory() async {
        await copyMarkdown(path: "/projects/markdown", label: "Project Memory") { message in
            projectMemoryCopyOutput = message
        }
    }

    func copySourceInventory() async {
        await copyMarkdown(path: "/sources/markdown", label: "Source Inventory") { message in
            sourceInventoryCopyOutput = message
        }
    }

    func copyMemoryBrief() async {
        await copyMarkdown(path: "/memory/markdown", label: "Memory Brief") { message in
            memoryBriefCopyOutput = message
        }
    }

    func previewMemoryLead(index: Int) async {
        await promoteMemoryLead(index: index, dryRun: true)
    }

    func promoteMemoryLead(index: Int, dryRun: Bool = false) async {
        guard let url = URL(string: "http://127.0.0.1:8765/memory/promote") else { return }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "index": max(1, index),
                "dryRun": dryRun
            ])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                memoryPromoteOutput = dryRun ? "Memory preview failed." : "Memory promotion failed."
                return
            }
            if dryRun {
                let title = json["title"] as? String ?? "Selected memory lead"
                let project = json["project"] as? String ?? "General Brain"
                memoryPromoteOutput = "Preview: \(title) -> \(project)"
            } else if json["ok"] as? Bool == true {
                let path = json["path"] as? String ?? "Oracle Inbox"
                memoryPromoteOutput = "Promoted memory lead to \(path)"
                oracleCommits = loadOracleCommits()
                projects = buildProjectMemories(feedItems: feedItems, oracleItems: oracleItems, oracleCommits: oracleCommits)
            } else {
                memoryPromoteOutput = json["error"] as? String ?? "Memory promotion failed."
            }
        } catch {
            memoryPromoteOutput = "Memory promotion failed: \(error.localizedDescription)"
        }
    }

    func previewRecentWork(index: Int) async {
        await promoteRecentWork(index: index, dryRun: true)
    }

    func promoteRecentWork(index: Int, dryRun: Bool = false) async {
        guard let url = URL(string: "http://127.0.0.1:8765/recent-work/promote") else { return }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "index": max(1, index),
                "dryRun": dryRun
            ])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                recentWorkPromoteOutput = dryRun ? "Recent work preview failed." : "Recent work promotion failed."
                return
            }
            if dryRun {
                let title = json["title"] as? String ?? "Selected recent work"
                recentWorkPromoteOutput = "Preview: \(title)"
            } else if json["ok"] as? Bool == true {
                let path = json["path"] as? String ?? "Oracle Inbox"
                recentWorkPromoteOutput = "Promoted recent work to \(path)"
                oracleCommits = loadOracleCommits()
                projects = buildProjectMemories(feedItems: feedItems, oracleItems: oracleItems, oracleCommits: oracleCommits)
            } else {
                recentWorkPromoteOutput = json["error"] as? String ?? "Recent work promotion failed."
            }
        } catch {
            recentWorkPromoteOutput = "Recent work promotion failed: \(error.localizedDescription)"
        }
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
        isAskingOracle = true
        defer { isAskingOracle = false }
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
                oracleSuggestedActions = []
                return
            }
            oracleMode = (json["mode"] as? String ?? "local").replacingOccurrences(of: "-", with: " ")
            oracleAnswer = answer
            oracleSuggestedActions = json["suggestedActions"] as? [String] ?? []
        } catch {
            oracleMode = "local"
            oracleAnswer = answerOracleQuestion(question, items: oracleItems, cards: cards)
            oracleSuggestedActions = []
        }
    }

    func askFocusOracle(_ item: FocusItem, question: String? = nil) async {
        let prompt = question?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let resolvedQuestion = prompt.isEmpty ? focusOracleQuestion(for: item, intent: "decide the next move") : prompt
        oracleQuestion = resolvedQuestion
        isAskingOracle = true
        defer { isAskingOracle = false }

        guard let url = URL(string: "http://127.0.0.1:8765/focus/ask") else {
            oracleAnswer = answerOracleQuestion(resolvedQuestion, items: oracleItems, cards: cards)
            oracleMode = "local"
            return
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["question": resolvedQuestion])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let answer = json["answer"] as? String else {
                oracleMode = "local"
                oracleAnswer = answerOracleQuestion(resolvedQuestion, items: oracleItems, cards: cards)
                oracleSuggestedActions = []
                return
            }
            oracleMode = (json["mode"] as? String ?? "focus").replacingOccurrences(of: "-", with: " ")
            oracleAnswer = answer
            oracleSuggestedActions = json["suggestedActions"] as? [String] ?? []
        } catch {
            oracleMode = "local"
            oracleAnswer = answerOracleQuestion(resolvedQuestion, items: oracleItems, cards: cards)
            oracleSuggestedActions = []
        }
    }

    func askBlindspot(_ item: BlindspotItem, commit: Bool = false) async {
        guard !isAskingBlindspot else { return }
        isAskingBlindspot = true
        blindspotAnswerTitle = item.title
        blindspotOutput = commit ? "Asking and committing..." : "Asking Oracle..."
        defer { isAskingBlindspot = false }

        guard let url = URL(string: "http://127.0.0.1:8765/blindspots/ask") else {
            blindspotOutput = "Blindspot ask failed."
            return
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "id": item.id,
                "question": item.question
            ])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let answer = json["answer"] as? String,
                  !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                blindspotOutput = "Blindspot ask failed."
                return
            }

            let resolvedQuestion = json["question"] as? String ?? item.question
            let groundedQuestion = json["groundedQuestion"] as? String ?? resolvedQuestion
            let mode = (json["mode"] as? String ?? "blindspot").replacingOccurrences(of: "-", with: " ")
            oracleQuestion = resolvedQuestion
            oracleAnswer = answer
            oracleMode = mode
            oracleSuggestedActions = json["suggestedActions"] as? [String] ?? []
            blindspotAnswer = answer
            blindspotOutput = "Oracle answered."

            if commit {
                await commitBlindspotAnswer(
                    answer: answer,
                    question: groundedQuestion,
                    suggestion: json["commitSuggestion"] as? [String: Any] ?? [:],
                    fallback: item
                )
            }
        } catch {
            blindspotOutput = "Blindspot ask failed: \(error.localizedDescription)"
        }
    }

    private func commitBlindspotAnswer(answer: String, question: String, suggestion: [String: Any], fallback: BlindspotItem) async {
        guard let url = URL(string: "http://127.0.0.1:8765/oracle/commit") else { return }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "title": suggestion["title"] as? String ?? "Blindspot - \(fallback.title)",
                "question": question,
                "content": answer,
                "source": "Terminal Brain.app Blindspot Brief",
                "project": suggestion["project"] as? String ?? fallback.project,
                "tags": suggestion["tags"] as? [String] ?? ["terminal-brain", "blindspot", "oracle"]
            ])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["ok"] as? Bool == true,
                  let path = json["path"] as? String else {
                blindspotOutput = "Blindspot commit failed."
                return
            }
            blindspotOutput = "Committed to \(path)"
            oracleCommitOutput = blindspotOutput
            oracleCommits = loadOracleCommits()
            projects = buildProjectMemories(feedItems: feedItems, oracleItems: oracleItems, oracleCommits: oracleCommits)
            radarItems = buildRadarItems(cards: cards, setupSteps: setupSteps, projects: projects, oracleItems: oracleItems, oracleCommits: oracleCommits, feedItems: feedItems)
            dailyCommands = buildDailyCommands(cards: cards, projects: projects, oracleCommits: oracleCommits, feedItems: feedItems, radarItems: radarItems)
            rebuildOperatorBrief()
        } catch {
            blindspotOutput = "Blindspot commit failed: \(error.localizedDescription)"
        }
    }

    func resolveBlindspot(_ item: BlindspotItem) async {
        guard let url = URL(string: "http://127.0.0.1:8765/blindspots/action") else { return }
        blindspotOutput = "Resolving source..."
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "id": item.id,
                "status": "accepted",
                "disposition": "acted"
            ])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["ok"] as? Bool == true else {
                blindspotOutput = "Source is not directly resolvable."
                return
            }
            blindspotOutput = "Source resolved."
            oracleCommits = loadOracleCommits()
            projects = buildProjectMemories(feedItems: feedItems, oracleItems: oracleItems, oracleCommits: oracleCommits)
            radarItems = buildRadarItems(cards: cards, setupSteps: setupSteps, projects: projects, oracleItems: oracleItems, oracleCommits: oracleCommits, feedItems: feedItems)
            dailyCommands = buildDailyCommands(cards: cards, projects: projects, oracleCommits: oracleCommits, feedItems: feedItems, radarItems: radarItems)
            rebuildOperatorBrief()
        } catch {
            blindspotOutput = "Resolve failed: \(error.localizedDescription)"
        }
    }

    func askIdea(_ item: IdeaPulseItem, commit: Bool = false) async {
        guard !isAskingIdea else { return }
        isAskingIdea = true
        ideaAnswerTitle = item.title
        ideaOutput = commit ? "Pressure testing and committing..." : "Pressure testing..."
        defer { isAskingIdea = false }

        guard let url = URL(string: "http://127.0.0.1:8765/ideas/ask") else {
            ideaOutput = "Idea ask failed."
            return
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "id": item.id,
                "question": item.nextPrompt
            ])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let answer = json["answer"] as? String,
                  !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                ideaOutput = "Idea ask failed."
                return
            }

            let resolvedQuestion = json["question"] as? String ?? item.nextPrompt
            let groundedQuestion = json["groundedQuestion"] as? String ?? resolvedQuestion
            let mode = (json["mode"] as? String ?? "idea").replacingOccurrences(of: "-", with: " ")
            oracleQuestion = resolvedQuestion
            oracleAnswer = answer
            oracleMode = mode
            oracleSuggestedActions = json["suggestedActions"] as? [String] ?? []
            ideaAnswer = answer
            ideaOutput = "Idea pressure-tested."

            if commit {
                await commitIdeaAnswer(
                    answer: answer,
                    question: groundedQuestion,
                    suggestion: json["commitSuggestion"] as? [String: Any] ?? [:],
                    fallback: item
                )
            }
        } catch {
            ideaOutput = "Idea ask failed: \(error.localizedDescription)"
        }
    }

    private func commitIdeaAnswer(answer: String, question: String, suggestion: [String: Any], fallback: IdeaPulseItem) async {
        guard let url = URL(string: "http://127.0.0.1:8765/oracle/commit") else { return }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "title": suggestion["title"] as? String ?? "Idea Test - \(fallback.title)",
                "question": question,
                "content": answer,
                "source": "Terminal Brain.app Idea Pulse",
                "project": suggestion["project"] as? String ?? fallback.project,
                "tags": suggestion["tags"] as? [String] ?? ["terminal-brain", "idea", "pressure-test", "oracle"]
            ])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["ok"] as? Bool == true,
                  let path = json["path"] as? String else {
                ideaOutput = "Idea commit failed."
                return
            }
            ideaOutput = "Committed to \(path)"
            oracleCommitOutput = ideaOutput
            oracleCommits = loadOracleCommits()
            projects = buildProjectMemories(feedItems: feedItems, oracleItems: oracleItems, oracleCommits: oracleCommits)
            radarItems = buildRadarItems(cards: cards, setupSteps: setupSteps, projects: projects, oracleItems: oracleItems, oracleCommits: oracleCommits, feedItems: feedItems)
            dailyCommands = buildDailyCommands(cards: cards, projects: projects, oracleCommits: oracleCommits, feedItems: feedItems, radarItems: radarItems)
            rebuildOperatorBrief()
        } catch {
            ideaOutput = "Idea commit failed: \(error.localizedDescription)"
        }
    }

    func focusOracleQuestion(for item: FocusItem, intent: String) -> String {
        [
            intent,
            "Focus: \(item.title)",
            "Project: \(item.project)",
            "Reason: \(item.reason)",
            "Current action: \(item.action)"
        ].joined(separator: "\n")
    }

    func commitOracleAnswer(project: String? = nil) async {
        let content = oracleAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        guard let url = URL(string: "http://127.0.0.1:8765/oracle/commit") else { return }
        let explicitProject = project?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedProject = explicitProject?.isEmpty == false ? explicitProject ?? "" : projectName(from: "\(oracleQuestion) \(content)")
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "title": "Oracle - \(oracleQuestion.trimmingCharacters(in: .whitespacesAndNewlines))",
                "question": oracleQuestion,
                "content": content,
                "source": "Terminal Brain.app",
                "project": resolvedProject,
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
            radarItems = buildRadarItems(cards: cards, setupSteps: setupSteps, projects: projects, oracleItems: oracleItems, oracleCommits: oracleCommits, feedItems: feedItems)
            dailyCommands = buildDailyCommands(cards: cards, projects: projects, oracleCommits: oracleCommits, feedItems: feedItems, radarItems: radarItems)
            rebuildOperatorBrief()
        } catch {
            oracleCommitOutput = "Commit failed: \(error.localizedDescription)"
        }
    }

    func captureIdea(project: String? = nil) async {
        let content = quickIdea.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        guard let url = URL(string: "http://127.0.0.1:8765/ideas/capture") else { return }
        let resolvedProject = project?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "title": titleForIdea(content),
                "content": content,
                "project": resolvedProject,
                "tags": ["terminal-brain", "idea", "capture"]
            ])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["ok"] as? Bool == true,
                  let path = json["path"] as? String else {
                quickIdeaOutput = "Idea capture failed."
                return
            }
            quickIdea = ""
            quickIdeaOutput = "Captured to \(path)"
            oracleCommits = loadOracleCommits()
            projects = buildProjectMemories(feedItems: feedItems, oracleItems: oracleItems, oracleCommits: oracleCommits)
            radarItems = buildRadarItems(cards: cards, setupSteps: setupSteps, projects: projects, oracleItems: oracleItems, oracleCommits: oracleCommits, feedItems: feedItems)
            dailyCommands = buildDailyCommands(cards: cards, projects: projects, oracleCommits: oracleCommits, feedItems: feedItems, radarItems: radarItems)
            rebuildOperatorBrief()
        } catch {
            quickIdeaOutput = "Idea capture failed: \(error.localizedDescription)"
        }
    }

    func commitOutcome(project: String? = nil) async {
        let outcome = outcomeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !outcome.isEmpty else { return }
        guard let url = URL(string: "http://127.0.0.1:8765/outcomes/commit") else { return }
        let title = outcomeTitle.trimmingCharacters(in: .whitespacesAndNewlines).ifEmpty("Work Block Outcome")
        let nextAction = outcomeNextAction.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedProject = project?.trimmingCharacters(in: .whitespacesAndNewlines).ifEmpty(focusItem.project) ?? focusItem.project

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "title": title,
                "outcome": outcome,
                "nextAction": nextAction,
                "project": resolvedProject,
                "source": "Terminal Brain.app",
                "tags": ["terminal-brain", "outcome", "start-here"],
                "evidence": [
                    "Focus: \(focusItem.title)",
                    "Project: \(resolvedProject)"
                ]
            ])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["ok"] as? Bool == true,
                  let path = json["path"] as? String else {
                outcomeOutput = "Outcome commit failed."
                return
            }
            outcomeTitle = ""
            outcomeText = ""
            outcomeNextAction = ""
            outcomeOutput = "Committed to \(path)"
            oracleCommits = loadOracleCommits()
            projects = buildProjectMemories(feedItems: feedItems, oracleItems: oracleItems, oracleCommits: oracleCommits)
            radarItems = buildRadarItems(cards: cards, setupSteps: setupSteps, projects: projects, oracleItems: oracleItems, oracleCommits: oracleCommits, feedItems: feedItems)
            dailyCommands = buildDailyCommands(cards: cards, projects: projects, oracleCommits: oracleCommits, feedItems: feedItems, radarItems: radarItems)
            rebuildOperatorBrief()
        } catch {
            outcomeOutput = "Outcome commit failed: \(error.localizedDescription)"
        }
    }

    func copyOperatorSnapshot() async {
        guard let url = URL(string: "http://127.0.0.1:8765/snapshot/markdown") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let markdown = String(data: data, encoding: .utf8), !markdown.isEmpty else {
                snapshotCopyOutput = "Snapshot copy failed."
                return
            }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(markdown, forType: .string)
            snapshotCopyOutput = "Snapshot copied."
        } catch {
            snapshotCopyOutput = "Snapshot copy failed: \(error.localizedDescription)"
        }
    }

    func copyOperatorDeck() async {
        guard let url = URL(string: "http://127.0.0.1:8765/operator-deck/markdown") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let markdown = String(data: data, encoding: .utf8), !markdown.isEmpty else {
                deckCopyOutput = "Deck copy failed."
                return
            }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(markdown, forType: .string)
            deckCopyOutput = "Deck copied."
        } catch {
            deckCopyOutput = "Deck copy failed: \(error.localizedDescription)"
        }
    }

    private func copyMarkdown(path: String, label: String, setOutput: (String) -> Void) async {
        guard let url = URL(string: "http://127.0.0.1:8765\(path)") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let markdown = String(data: data, encoding: .utf8), !markdown.isEmpty else {
                setOutput("\(label) copy failed.")
                return
            }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(markdown, forType: .string)
            setOutput("\(label) copied.")
        } catch {
            setOutput("\(label) copy failed: \(error.localizedDescription)")
        }
    }

    func askOracle(for project: ProjectMemory) async {
        oracleQuestion = "What changed for \(project.name), what matters now, and what should I do next?"
        await askOracle()
    }

    func buildPack(for project: ProjectMemory) async {
        workQuery = project.name
        await startWork()
    }

    func commitProjectUpdate(_ project: ProjectMemory) async {
        guard let url = URL(string: "http://127.0.0.1:8765/oracle/commit") else { return }
        let signals = [
            "Summary: \(project.summary)",
            "Recommended next action: \(project.recommendedAction)",
            "Context packs: \(project.contextPacks.map(\.title).joined(separator: ", ").ifEmpty("none"))",
            "Open loops: \(project.openLoops.map(\.title).joined(separator: ", ").ifEmpty("none"))",
            "Decisions: \(project.decisions.map(\.title).joined(separator: ", ").ifEmpty("none"))"
        ].joined(separator: "\n\n")
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "title": "Project Update - \(project.name)",
                "question": "What is the current operating state for \(project.name)?",
                "content": signals,
                "source": "Terminal Brain Project Memory",
                "project": project.name,
                "tags": ["terminal-brain", "project-memory", projectID(from: project.name)]
            ])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["ok"] as? Bool == true,
                  let path = json["path"] as? String else {
                oracleCommitOutput = "Project update commit failed."
                return
            }
            oracleCommitOutput = "Committed project update to \(path)"
            oracleCommits = loadOracleCommits()
            projects = buildProjectMemories(feedItems: feedItems, oracleItems: oracleItems, oracleCommits: oracleCommits)
            radarItems = buildRadarItems(cards: cards, setupSteps: setupSteps, projects: projects, oracleItems: oracleItems, oracleCommits: oracleCommits, feedItems: feedItems)
            dailyCommands = buildDailyCommands(cards: cards, projects: projects, oracleCommits: oracleCommits, feedItems: feedItems, radarItems: radarItems)
            rebuildOperatorBrief()
        } catch {
            oracleCommitOutput = "Project update commit failed: \(error.localizedDescription)"
        }
    }

    func commitRadarItem(_ item: RadarItem) async {
        guard let url = URL(string: "http://127.0.0.1:8765/oracle/commit") else { return }
        let content = [
            "Radar signal: \(item.title)",
            "Project: \(item.project)",
            "Urgency: \(item.urgency)",
            "Score: \(item.score)",
            "Evidence: \(item.evidence.joined(separator: ", ").ifEmpty("none"))",
            "Recommended action: \(item.action)",
            "Detail: \(item.detail)",
            "Reason: \(item.reason)",
            item.path.map { "Source path: \($0)" } ?? ""
        ].filter { !$0.isEmpty }.joined(separator: "\n\n")

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "title": "Radar Signal - \(item.title)",
                "question": "What did Terminal Brain Radar surface?",
                "content": content,
                "source": "Terminal Brain Radar",
                "project": item.project,
                "tags": ["terminal-brain", "radar", item.urgency.lowercased()]
            ])
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["ok"] as? Bool == true,
                  let path = json["path"] as? String else {
                oracleCommitOutput = "Radar commit failed."
                return
            }
            oracleCommitOutput = "Committed radar signal to \(path)"
            oracleCommits = loadOracleCommits()
            projects = buildProjectMemories(feedItems: feedItems, oracleItems: oracleItems, oracleCommits: oracleCommits)
            radarItems = buildRadarItems(cards: cards, setupSteps: setupSteps, projects: projects, oracleItems: oracleItems, oracleCommits: oracleCommits, feedItems: feedItems)
            dailyCommands = buildDailyCommands(cards: cards, projects: projects, oracleCommits: oracleCommits, feedItems: feedItems, radarItems: radarItems)
            rebuildOperatorBrief()
        } catch {
            oracleCommitOutput = "Radar commit failed: \(error.localizedDescription)"
        }
    }

    func setRadarDisposition(_ item: RadarItem, disposition: RadarDisposition) {
        var records = radarDispositionRecords()
        if disposition == .fresh {
            records.removeValue(forKey: item.id)
        } else {
            var record = [
                "disposition": disposition.rawValue,
                "updatedAt": ISO8601DateFormatter().string(from: Date())
            ]
            if disposition == .snoozed, let until = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                record["snoozedUntil"] = ISO8601DateFormatter().string(from: until)
            }
            records[item.id] = record
        }
        saveRadarDispositionRecords(records)
        radarItems = buildRadarItems(cards: cards, setupSteps: setupSteps, projects: projects, oracleItems: oracleItems, oracleCommits: oracleCommits, feedItems: feedItems)
        dailyCommands = buildDailyCommands(cards: cards, projects: projects, oracleCommits: oracleCommits, feedItems: feedItems, radarItems: radarItems)
        rebuildOperatorBrief()
    }

    func delegateOracleCommitToStartWork(_ commit: OracleCommit) {
        setOracleCommitStatus(commit, status: .delegated)
        workQuery = [commit.project, commit.title]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " - ")
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
        radarItems = buildRadarItems(cards: cards, setupSteps: setupSteps, projects: projects, oracleItems: oracleItems, oracleCommits: oracleCommits, feedItems: feedItems)
        dailyCommands = buildDailyCommands(cards: cards, projects: projects, oracleCommits: oracleCommits, feedItems: feedItems, radarItems: radarItems)
        rebuildOperatorBrief()
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
        radarItems = buildRadarItems(cards: cards, setupSteps: setupSteps, projects: projects, oracleItems: oracleItems, oracleCommits: oracleCommits, feedItems: feedItems)
        dailyCommands = buildDailyCommands(cards: cards, projects: projects, oracleCommits: oracleCommits, feedItems: feedItems, radarItems: radarItems)
        rebuildOperatorBrief()
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

    private func buildSetupSteps(from cards: [HealthCard]) -> [SetupStep] {
        func card(_ title: String) -> HealthCard? {
            cards.first { $0.title == title }
        }

        func exists(_ path: String, directory: Bool? = nil) -> Bool {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { return false }
            if let directory {
                return isDirectory.boolValue == directory
            }
            return true
        }

        let workspaceReady = exists(Paths.workspace, directory: true)
        let cliReady = exists(Paths.brainCLI)
        let syncReady = exists(Paths.syncScript)
        let obsidianReady = card("Obsidian Index")?.state == .good
        let missionReady = card("Mission Control")?.state == .good
        let codexReady = card("Codex MCP Config")?.state == .good
        let workspaceMCPReady = card("Workspace MCP Config")?.state == .good
        let promptSafe = (card("Apple Notes MCP")?.state != .warn)
            && (card("Drafts MCP")?.state != .warn)
            && (card("Hourly Sync Agent")?.state != .warn)
        let oracleReady = exists(Paths.oracleInbox, directory: true)

        return [
            SetupStep(
                id: "workspace",
                title: "Workspace",
                detail: workspaceReady ? Paths.workspace : "Set the local workspace path in Settings.",
                state: workspaceReady ? .good : .warn,
                action: workspaceReady ? "Open Workspace" : "Open Settings",
                symbol: "folder"
            ),
            SetupStep(
                id: "brain-cli",
                title: "Start Work CLI",
                detail: cliReady ? Paths.brainCLI : "Set the brain CLI path before building context packs.",
                state: cliReady ? .good : .warn,
                action: cliReady ? "Start Work" : "Open Settings",
                symbol: "terminal"
            ),
            SetupStep(
                id: "sync-script",
                title: "Sync Script",
                detail: syncReady ? Paths.syncScript : "Set the Edge Brain sync wrapper path.",
                state: syncReady ? .good : .warn,
                action: syncReady ? "Run Sync" : "Open Settings",
                symbol: "arrow.triangle.2.circlepath"
            ),
            SetupStep(
                id: "obsidian-index",
                title: "Obsidian Index",
                detail: card("Obsidian Index")?.detail ?? "Run sync to populate local memory metadata.",
                state: obsidianReady ? .good : .warn,
                action: obsidianReady ? "Open Workspace" : "Run Sync",
                symbol: "doc.text.magnifyingglass"
            ),
            SetupStep(
                id: "mission",
                title: "Mission Control",
                detail: card("Mission Control")?.detail ?? Paths.missionURL.absoluteString,
                state: missionReady ? .good : .warn,
                action: missionReady ? "Open Mission" : "Open Settings",
                symbol: "display"
            ),
            SetupStep(
                id: "codex-mcp",
                title: "Codex MCP",
                detail: card("Codex MCP Config")?.detail ?? "Register the Terminal Brain MCP gateway.",
                state: codexReady ? .good : .warn,
                action: "Open Settings",
                symbol: "antenna.radiowaves.left.and.right"
            ),
            SetupStep(
                id: "workspace-mcp",
                title: "Workspace MCP",
                detail: card("Workspace MCP Config")?.detail ?? "Register the workspace MCP gateway.",
                state: workspaceMCPReady ? .good : .warn,
                action: "Open Workspace",
                symbol: "folder.badge.gearshape"
            ),
            SetupStep(
                id: "prompt-safety",
                title: "Prompt Safety",
                detail: promptSafe ? "Prompt-prone Apple Notes, Drafts, and hourly sync bridges are quiet." : "A prompt-prone bridge or background sync agent is active.",
                state: promptSafe ? .good : .warn,
                action: "Open Sources",
                symbol: "lock.shield.fill"
            ),
            SetupStep(
                id: "oracle-inbox",
                title: "Oracle Inbox",
                detail: oracleReady ? Paths.oracleInbox : "Create the Obsidian-backed Oracle Inbox by committing an Oracle read.",
                state: oracleReady ? .good : .warn,
                action: oracleReady ? "Open Review" : "Ask Oracle",
                symbol: "tray.and.arrow.down.fill"
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

    private func buildDailyCommands(cards: [HealthCard], projects: [ProjectMemory], oracleCommits: [OracleCommit], feedItems: [BrainFeedItem], radarItems: [RadarItem]) -> [DailyCommandItem] {
        var items: [DailyCommandItem] = []

        for radar in radarItems.prefix(2) {
            items.append(
                DailyCommandItem(
                    id: "radar-\(radar.id)",
                    title: radar.title,
                    detail: radar.detail,
                    priority: radar.urgency,
                    action: radar.action,
                    project: radar.project,
                    symbol: radar.symbol,
                    state: radar.state,
                    query: radar.query
                )
            )
        }

        for commit in oracleCommits.filter({ $0.status == .delegated }).prefix(3) {
            items.append(
                DailyCommandItem(
                    id: "delegated-\(commit.id)",
                    title: "Execute delegated read",
                    detail: commit.title,
                    priority: "Now",
                    action: "Start Work",
                    project: commit.project,
                    symbol: "paperplane.fill",
                    state: .busy,
                    query: [commit.project, commit.title].filter { !$0.isEmpty }.joined(separator: " - ")
                )
            )
        }

        for commit in oracleCommits.filter({ $0.status == .new }).prefix(3) {
            items.append(
                DailyCommandItem(
                    id: "review-\(commit.id)",
                    title: "Review new Oracle read",
                    detail: commit.preview,
                    priority: "Review",
                    action: "Open Review",
                    project: commit.project,
                    symbol: "tray.and.arrow.down.fill",
                    state: .warn,
                    query: commit.title
                )
            )
        }

        for project in projects.prefix(4) {
            items.append(
                DailyCommandItem(
                    id: "project-\(project.id)",
                    title: "Move \(project.name) forward",
                    detail: project.recommendedAction,
                    priority: project.delegatedCount > 0 ? "Now" : "Next",
                    action: "Open Project",
                    project: project.name,
                    symbol: project.symbol,
                    state: project.delegatedCount > 0 ? .busy : .good,
                    query: project.name
                )
            )
        }

        if let warning = cards.first(where: { $0.state == .warn }) {
            items.append(
                DailyCommandItem(
                    id: "warning-\(warning.title)",
                    title: "Fix system attention item",
                    detail: "\(warning.title): \(warning.detail)",
                    priority: "Safety",
                    action: "Open System",
                    project: "System",
                    symbol: warning.symbol,
                    state: .warn,
                    query: warning.title
                )
            )
        }

        if let fresh = feedItems.first(where: { $0.kind == .context }) {
            items.append(
                DailyCommandItem(
                    id: "fresh-\(fresh.id)",
                    title: "Use freshest context",
                    detail: fresh.title,
                    priority: "Context",
                    action: "Open Pack",
                    project: projectName(from: "\(fresh.title) \(fresh.detail)"),
                    symbol: "shippingbox.fill",
                    state: .good,
                    query: fresh.title
                )
            )
        }

        if items.isEmpty {
            items.append(
                DailyCommandItem(
                    id: "ask-oracle",
                    title: "Ask what changed",
                    detail: "No urgent queue is visible. Ask Oracle to surface the next useful move.",
                    priority: "Start",
                    action: "Ask Oracle",
                    project: "General Brain",
                    symbol: "sparkle.magnifyingglass",
                    state: .good,
                    query: "What changed and what should I do first?"
                )
            )
        }

        return dedupeDailyCommands(items).prefix(8).map { $0 }
    }

    private func buildFocusItem(radarItems: [RadarItem], dailyCommands: [DailyCommandItem]) -> FocusItem {
        if let radar = radarItems.first {
            return FocusItem(
                id: radar.id,
                title: radar.title,
                detail: radar.detail,
                reason: radar.evidence.isEmpty ? radar.reason : radar.evidence.joined(separator: " • "),
                action: radar.action,
                project: radar.project,
                score: radar.score,
                symbol: radar.symbol,
                state: radar.state,
                query: radar.query,
                path: radar.path
            )
        }
        if let command = dailyCommands.first {
            return FocusItem(
                id: command.id,
                title: command.title,
                detail: command.detail,
                reason: "Top item from the Daily Command Center.",
                action: command.action,
                project: command.project,
                score: 0,
                symbol: command.symbol,
                state: command.state,
                query: command.query,
                path: nil
            )
        }
        return FocusItem(
            id: "ask-oracle",
            title: "Ask what changed",
            detail: "No active signal is available yet.",
            reason: "Run sync or ask Oracle to create a useful starting point.",
            action: "Ask Oracle",
            project: "General Brain",
            score: 0,
            symbol: "sparkle.magnifyingglass",
            state: .good,
            query: "What am I not considering right now?",
            path: nil
        )
    }

    private func buildOperatorBrief(cards: [HealthCard], focus: FocusItem, radarItems: [RadarItem], projects: [ProjectMemory], oracleCommits: [OracleCommit], oracleItems: [OracleItem], feedItems: [BrainFeedItem]) -> [OperatorBriefItem] {
        var items: [OperatorBriefItem] = [
            OperatorBriefItem(
                id: "matters",
                label: "What matters",
                title: focus.title,
                detail: focus.detail,
                action: focus.action,
                project: focus.project,
                symbol: focus.symbol,
                state: focus.state,
                query: focus.query
            ),
            OperatorBriefItem(
                id: "why",
                label: "Why it matters",
                title: focus.score > 0 ? "Signal score \(focus.score)" : "Top visible queue item",
                detail: focus.reason,
                action: "Ask Oracle",
                project: focus.project,
                symbol: "list.bullet.clipboard",
                state: focus.state,
                query: "Why does \(focus.title) matter right now?"
            )
        ]

        if let commit = oracleCommits.first(where: { $0.status == .new }) {
            items.append(
                OperatorBriefItem(
                    id: "missed-\(commit.id)",
                    label: "Do not miss",
                    title: "Unreviewed Oracle read",
                    detail: commit.preview,
                    action: "Open Review",
                    project: commit.project,
                    symbol: commit.status.symbol,
                    state: .warn,
                    query: commit.title
                )
            )
        } else if let oracle = oracleItems.first {
            items.append(
                OperatorBriefItem(
                    id: "missed-\(oracle.id)",
                    label: "Do not miss",
                    title: oracle.title,
                    detail: oracle.detail,
                    action: "Ask Oracle",
                    project: projectName(from: "\(oracle.title) \(oracle.detail)"),
                    symbol: oracle.symbol,
                    state: .good,
                    query: "What should I notice about \(oracle.title)?"
                )
            )
        } else if let warning = cards.first(where: { $0.state == .warn }) {
            items.append(
                OperatorBriefItem(
                    id: "missed-\(warning.title)",
                    label: "Do not miss",
                    title: warning.title,
                    detail: warning.detail,
                    action: "Open System",
                    project: "System",
                    symbol: warning.symbol,
                    state: .warn,
                    query: warning.title
                )
            )
        }

        if let delegated = oracleCommits.first(where: { $0.status == .delegated }) {
            items.append(
                OperatorBriefItem(
                    id: "artifact-\(delegated.id)",
                    label: "Next artifact",
                    title: "Build a handoff",
                    detail: delegated.title,
                    action: "Start Work",
                    project: delegated.project,
                    symbol: "shippingbox.fill",
                    state: .busy,
                    query: [delegated.project, delegated.title].filter { !$0.isEmpty }.joined(separator: " - ")
                )
            )
        } else if let project = projects.first {
            items.append(
                OperatorBriefItem(
                    id: "artifact-\(project.id)",
                    label: "Next artifact",
                    title: project.name,
                    detail: project.recommendedAction,
                    action: "Open Project",
                    project: project.name,
                    symbol: project.symbol,
                    state: project.delegatedCount > 0 ? .busy : .good,
                    query: project.name
                )
            )
        } else if let pack = feedItems.first(where: { $0.kind == .context }) {
            items.append(
                OperatorBriefItem(
                    id: "artifact-\(pack.id)",
                    label: "Next artifact",
                    title: "Use latest context pack",
                    detail: pack.title,
                    action: "Open Pack",
                    project: projectName(from: "\(pack.title) \(pack.detail)"),
                    symbol: pack.symbol,
                    state: pack.state,
                    query: pack.title
                )
            )
        } else if let radar = radarItems.first {
            items.append(
                OperatorBriefItem(
                    id: "artifact-\(radar.id)",
                    label: "Next artifact",
                    title: "Turn signal into handoff",
                    detail: radar.reason,
                    action: radar.action,
                    project: radar.project,
                    symbol: radar.symbol,
                    state: radar.state,
                    query: radar.query
                )
            )
        }

        return Array(items.prefix(4))
    }

    private func buildIdeaPulse(oracleItems: [OracleItem], oracleCommits: [OracleCommit], projects: [ProjectMemory], feedItems: [BrainFeedItem]) -> [IdeaPulseItem] {
        var items: [IdeaPulseItem] = []

        for commit in oracleCommits.filter({ $0.tags.contains("idea") || $0.tags.contains("capture") }).prefix(8) {
            let unresolved = commit.status == .new || commit.status == .delegated
            items.append(
                IdeaPulseItem(
                    id: "commit-\(commit.id)",
                    title: commit.title,
                    detail: commit.preview,
                    whyNow: unresolved ? "This captured idea is still unclassified. Decide whether it deserves a test, a project link, or dismissal." : "This idea has been classified, but it may still be useful as project memory.",
                    nextPrompt: "What is the cheapest test for this idea, and what would make it not worth pursuing?",
                    project: commit.project,
                    source: "Oracle Inbox",
                    score: unresolved ? 86 : 58,
                    symbol: "lightbulb.fill",
                    state: unresolved ? .warn : .good,
                    path: commit.path
                )
            )
        }

        for item in oracleItems.filter({ $0.kind == .idea || $0.kind == .opportunity || $0.kind == .bubbling }).prefix(8) {
            let project = projectName(from: "\(item.title) \(item.detail) \(item.source)")
            let isIdea = item.kind == .idea
            items.append(
                IdeaPulseItem(
                    id: "oracle-\(item.id)",
                    title: item.title,
                    detail: item.detail,
                    whyNow: isIdea ? "This surfaced as an idea signal. It needs a small test before it becomes real work." : "This is bubbling up from recent context and may be a useful adjacent opportunity.",
                    nextPrompt: isIdea ? "What is the smallest proof that this idea is worth keeping?" : "What decision would turn this opportunity into a useful next action?",
                    project: project,
                    source: item.source,
                    score: isIdea ? 78 : 70,
                    symbol: item.symbol,
                    state: .good,
                    path: item.path
                )
            )
        }

        for project in projects.prefix(8) where project.signalCount > 0 && project.delegatedCount == 0 {
            items.append(
                IdeaPulseItem(
                    id: "project-\(project.id)",
                    title: "Untested edge for \(project.name)",
                    detail: project.recommendedAction,
                    whyNow: "This project has memory attached but no delegated execution edge. It may need a sharper experiment instead of more browsing.",
                    nextPrompt: "What would prove the next useful artifact for \(project.name) in under an hour?",
                    project: project.name,
                    source: "Project Memory",
                    score: max(50, min(76, 54 + project.signalCount * 4)),
                    symbol: project.symbol,
                    state: .good,
                    path: project.contextPacks.first?.path
                )
            )
        }

        if let fresh = feedItems.first(where: { $0.kind == .context }) {
            items.append(
                IdeaPulseItem(
                    id: "context-\(fresh.id)",
                    title: "Fresh context worth mining",
                    detail: fresh.title,
                    whyNow: "The newest context pack may contain a useful idea or open loop before it goes stale.",
                    nextPrompt: "What idea, risk, or unresolved question is hidden in \(fresh.title)?",
                    project: projectName(from: "\(fresh.title) \(fresh.detail)"),
                    source: "Context pack",
                    score: 62,
                    symbol: fresh.symbol,
                    state: .good,
                    path: fresh.path
                )
            )
        }

        if items.isEmpty {
            items.append(
                IdeaPulseItem(
                    id: "fallback",
                    title: "Capture the next raw thought",
                    detail: "No strong idea signal is visible yet.",
                    whyNow: "The system needs captured material before it can surface surprising connections.",
                    nextPrompt: "What rough idea keeps returning, even if it is not ready?",
                    project: "General Brain",
                    source: "Fallback",
                    score: 35,
                    symbol: "lightbulb",
                    state: .good,
                    path: nil
                )
            )
        }

        var seen = Set<String>()
        return items
            .sorted {
                if $0.score == $1.score {
                    return $0.title < $1.title
                }
                return $0.score > $1.score
            }
            .filter { item in
                let key = "\(item.title)-\(item.project)-\(item.source)".lowercased()
                guard !seen.contains(key) else { return false }
                seen.insert(key)
                return true
            }
            .prefix(10)
            .map { $0 }
    }

    private func buildBlindspots(focus: FocusItem, radarItems: [RadarItem], setupSteps: [SetupStep], projects: [ProjectMemory], oracleItems: [OracleItem], oracleCommits: [OracleCommit]) -> [BlindspotItem] {
        var items: [BlindspotItem] = []

        if let delegated = oracleCommits.first(where: { $0.status == .delegated }) {
            items.append(
                BlindspotItem(
                    id: "delegated-\(delegated.id)",
                    title: "Delegation without artifact",
                    why: "This read is already marked delegated. It needs to become a Start Work pack or agent handoff, not another parked note.",
                    question: "What concrete artifact should this delegated read become?",
                    nextAction: "Start Work",
                    project: delegated.project,
                    source: "Oracle commit",
                    sourceID: delegated.id,
                    score: 96,
                    symbol: "paperplane.fill",
                    state: .busy,
                    path: delegated.path
                )
            )
        }

        if let review = oracleCommits.first(where: { $0.status == .new }) {
            items.append(
                BlindspotItem(
                    id: "review-\(review.id)",
                    title: "Decision debt in the Oracle Inbox",
                    why: "Committed reads are only useful after they are accepted, linked, delegated, or dismissed.",
                    question: "Is this read accepted, linked to a project, delegated, or dismissed?",
                    nextAction: "Review",
                    project: review.project,
                    source: "Oracle commit",
                    sourceID: review.id,
                    score: 92,
                    symbol: "tray.and.arrow.down.fill",
                    state: .warn,
                    path: review.path
                )
            )
        }

        if let openLoop = oracleItems.first(where: { $0.kind == .openLoop }) {
            items.append(
                BlindspotItem(
                    id: "loop-\(openLoop.id)",
                    title: "Open loop resurfacing",
                    why: openLoop.detail,
                    question: "What would make this loop closed enough to stop resurfacing?",
                    nextAction: "Start Work",
                    project: projectName(from: "\(openLoop.title) \(openLoop.detail)"),
                    source: openLoop.source,
                    sourceID: openLoop.id,
                    score: 86,
                    symbol: openLoop.symbol,
                    state: .warn,
                    path: openLoop.path
                )
            )
        }

        if let idea = oracleItems.first(where: { $0.kind == .idea || $0.kind == .opportunity || $0.kind == .bubbling }) {
            items.append(
                BlindspotItem(
                    id: "idea-\(idea.id)",
                    title: "Idea that needs pressure testing",
                    why: idea.detail,
                    question: "What is the cheapest test that would prove whether this idea is worth keeping?",
                    nextAction: "Ask Oracle",
                    project: projectName(from: "\(idea.title) \(idea.detail)"),
                    source: idea.source,
                    sourceID: idea.id,
                    score: 78,
                    symbol: idea.symbol,
                    state: .good,
                    path: idea.path
                )
            )
        }

        if let project = projects.first(where: { $0.signalCount >= 2 && $0.delegatedCount == 0 }) {
            items.append(
                BlindspotItem(
                    id: "project-\(project.id)",
                    title: "Active project without an execution edge",
                    why: project.recommendedAction,
                    question: "What is the one artifact that would move \(project.name) forward today?",
                    nextAction: "Open Project",
                    project: project.name,
                    source: "Project Memory",
                    sourceID: project.id,
                    score: 72,
                    symbol: project.symbol,
                    state: .good,
                    path: project.contextPacks.first?.path
                )
            )
        }

        if let secondSignal = radarItems.first(where: { $0.id != focus.id }) {
            items.append(
                BlindspotItem(
                    id: "radar-\(secondSignal.id)",
                    title: "Second-order signal",
                    why: "This did not win the focus slot, but its score is high enough that it may be underweighted.",
                    question: "Why is this not the first thing you are doing?",
                    nextAction: secondSignal.action,
                    project: secondSignal.project,
                    source: "Radar",
                    sourceID: secondSignal.id,
                    score: max(secondSignal.score - 4, 50),
                    symbol: secondSignal.symbol,
                    state: secondSignal.state,
                    path: secondSignal.path
                )
            )
        }

        if let gap = setupSteps.first(where: { $0.state == .warn }) {
            items.append(
                BlindspotItem(
                    id: "setup-\(gap.id)",
                    title: "System assumption to verify",
                    why: gap.detail,
                    question: "Does this gap change which agent work is safe to delegate?",
                    nextAction: gap.action,
                    project: "System",
                    source: "Setup",
                    sourceID: gap.id,
                    score: 70,
                    symbol: gap.symbol,
                    state: .warn,
                    path: nil
                )
            )
        }

        if items.isEmpty {
            items.append(
                BlindspotItem(
                    id: "fallback",
                    title: "No blindspot candidate is strong enough yet",
                    why: "No stale review debt, delegated work, project drift, or resurfacing open loops were found in the current local scan.",
                    question: "What changed since the last sync that is not represented in durable memory?",
                    nextAction: "Capture Idea",
                    project: "General Brain",
                    source: "Fallback",
                    sourceID: "fallback",
                    score: 40,
                    symbol: "sparkle.magnifyingglass",
                    state: .good,
                    path: nil
                )
            )
        }

        var seen = Set<String>()
        return items
            .sorted { $0.score > $1.score }
            .filter { item in
                let key = "\(item.title)-\(item.project)-\(item.sourceID)".lowercased()
                guard !seen.contains(key) else { return false }
                seen.insert(key)
                return true
            }
            .prefix(6)
            .map { $0 }
    }

    private func buildRadarItems(cards: [HealthCard], setupSteps: [SetupStep], projects: [ProjectMemory], oracleItems: [OracleItem], oracleCommits: [OracleCommit], feedItems: [BrainFeedItem]) -> [RadarItem] {
        var items: [RadarItem] = []

        for commit in oracleCommits.filter({ $0.status == .delegated }).prefix(3) {
            items.append(
                RadarItem(
                    id: "delegated-\(commit.id)",
                    title: "Delegated read needs execution",
                    detail: commit.title,
                    reason: "You already marked this as delegated. It should become a context pack or agent handoff instead of sitting in review.",
                    action: "Start Work",
                    project: commit.project,
                    urgency: "Now",
                    symbol: "paperplane.fill",
                    state: .busy,
                    disposition: .fresh,
                    score: 0,
                    evidence: [],
                    query: [commit.project, commit.title].filter { !$0.isEmpty }.joined(separator: " - "),
                    path: commit.path
                )
            )
        }

        for step in setupSteps.filter({ $0.state == .warn }).prefix(2) {
            items.append(
                RadarItem(
                    id: "setup-\(step.id)",
                    title: "Readiness gap: \(step.title)",
                    detail: step.detail,
                    reason: "This weakens agent reliability or source coverage. Fix it before trusting automation-heavy work.",
                    action: step.action,
                    project: "System",
                    urgency: "Safety",
                    symbol: step.symbol,
                    state: .warn,
                    disposition: .fresh,
                    score: 0,
                    evidence: [],
                    query: step.title,
                    path: nil
                )
            )
        }

        for commit in oracleCommits.filter({ $0.status == .new }).prefix(3) {
            let ageHours = max(0, Int(Date().timeIntervalSince(commit.created) / 3600))
            items.append(
                RadarItem(
                    id: "review-\(commit.id)",
                    title: ageHours >= 24 ? "Stale Oracle read" : "Unclassified Oracle read",
                    detail: commit.preview,
                    reason: ageHours >= 24 ? "This has been waiting about \(ageHours / 24) day\(ageHours / 24 == 1 ? "" : "s"). Accept, link, delegate, or dismiss it so it stops floating." : "A useful answer is only durable when it is accepted, linked, delegated, or dismissed.",
                    action: "Open Review",
                    project: commit.project,
                    urgency: ageHours >= 24 ? "Review" : "Triage",
                    symbol: commit.status.symbol,
                    state: .warn,
                    disposition: .fresh,
                    score: 0,
                    evidence: [],
                    query: commit.title,
                    path: commit.path
                )
            )
        }

        for project in projects.prefix(5) {
            if project.delegatedCount > 0 || !project.openLoops.isEmpty {
                items.append(
                    RadarItem(
                        id: "project-\(project.id)",
                        title: "Project wants a decision",
                        detail: project.recommendedAction,
                        reason: "\(project.name) has \(project.openLoops.count) open loop\(project.openLoops.count == 1 ? "" : "s") and \(project.delegatedCount) delegated read\(project.delegatedCount == 1 ? "" : "s").",
                        action: "Open Project",
                        project: project.name,
                        urgency: project.delegatedCount > 0 ? "Now" : "Next",
                        symbol: project.symbol,
                        state: project.delegatedCount > 0 ? .busy : .good,
                        disposition: .fresh,
                        score: 0,
                        evidence: [],
                        query: project.name,
                        path: project.contextPacks.first?.path
                    )
                )
            } else if project.lastActivity != Date.distantPast && Date().timeIntervalSince(project.lastActivity) > 7 * 24 * 3600 {
                items.append(
                    RadarItem(
                        id: "stale-\(project.id)",
                        title: "Quiet project worth resurfacing",
                        detail: project.summary,
                        reason: "This project has durable memory but no recent activity. Ask Oracle whether it should be advanced, archived, or ignored.",
                        action: "Ask Oracle",
                        project: project.name,
                        urgency: "Review",
                        symbol: project.symbol,
                        state: .warn,
                        disposition: .fresh,
                        score: 0,
                        evidence: [],
                        query: "Should I revive, archive, or ignore \(project.name)?",
                        path: project.contextPacks.first?.path
                    )
                )
            }
        }

        for item in oracleItems.filter({ $0.kind == .idea || $0.kind == .opportunity || $0.kind == .openLoop }).prefix(5) {
            items.append(
                RadarItem(
                    id: "oracle-\(item.id)",
                    title: item.kind == .openLoop ? "Open loop resurfaced" : "Idea worth testing",
                    detail: item.title,
                    reason: item.detail,
                    action: item.kind == .openLoop ? "Start Work" : "Ask Oracle",
                    project: projectName(from: "\(item.title) \(item.detail) \(item.source)"),
                    urgency: item.kind == .openLoop ? "Next" : "Explore",
                    symbol: item.symbol,
                    state: item.kind == .openLoop ? .warn : .good,
                    disposition: .fresh,
                    score: 0,
                    evidence: [],
                    query: item.kind == .openLoop ? item.title : "Is this idea worth acting on: \(item.title)?",
                    path: item.path
                )
            )
        }

        if let fresh = feedItems.first(where: { $0.kind == .context }) {
            items.append(
                RadarItem(
                    id: "fresh-\(fresh.id)",
                    title: "Fresh context pack is ready",
                    detail: fresh.title,
                    reason: "This is the newest agent handoff material. Use it while it is fresh or commit what changed.",
                    action: "Open Pack",
                    project: projectName(from: "\(fresh.title) \(fresh.detail)"),
                    urgency: "Context",
                    symbol: fresh.symbol,
                    state: .good,
                    disposition: .fresh,
                    score: 0,
                    evidence: [],
                    query: fresh.title,
                    path: fresh.path
                )
            )
        }

        if items.isEmpty {
            items.append(
                RadarItem(
                    id: "ask-oracle",
                    title: "No strong signal yet",
                    detail: "Ask Oracle what changed, then commit anything useful into the Oracle Inbox.",
                    reason: "Radar needs fresh context, committed reads, or source signals to become specific.",
                    action: "Ask Oracle",
                    project: "General Brain",
                    urgency: "Start",
                    symbol: "sparkle.magnifyingglass",
                    state: .good,
                    disposition: .fresh,
                    score: 0,
                    evidence: [],
                    query: "What am I not considering right now?",
                    path: nil
                )
            )
        }

        return rankRadarItems(applyRadarDisposition(to: dedupeRadarItems(items))).prefix(12).map { $0 }
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

    private func dedupeDailyCommands(_ items: [DailyCommandItem]) -> [DailyCommandItem] {
        var seen = Set<String>()
        var output: [DailyCommandItem] = []
        for item in items {
            let key = "\(item.title)-\(item.project)-\(item.query)".lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            output.append(item)
        }
        return output
    }

    private func dedupeRadarItems(_ items: [RadarItem]) -> [RadarItem] {
        var seen = Set<String>()
        var output: [RadarItem] = []
        for item in items {
            let key = "\(item.title)-\(item.project)-\(item.query)".lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            output.append(item)
        }
        return output
    }

    private func applyRadarDisposition(to items: [RadarItem]) -> [RadarItem] {
        let records = radarDispositionRecords()
        let now = Date()
        return items.compactMap { item in
            guard let record = records[item.id],
                  let rawDisposition = record["disposition"],
                  let disposition = RadarDisposition(rawValue: rawDisposition) else {
                return item
            }
            if disposition == .dismissed || disposition == .acted {
                return nil
            }
            if disposition == .snoozed,
               let rawUntil = record["snoozedUntil"],
               let until = ISO8601DateFormatter().date(from: rawUntil),
               until > now {
                return nil
            }
            if disposition == .snoozed {
                return withRadarDisposition(item, .fresh)
            }
            return withRadarDisposition(item, disposition)
        }
    }

    private func withRadarDisposition(_ item: RadarItem, _ disposition: RadarDisposition) -> RadarItem {
        RadarItem(
            id: item.id,
            title: item.title,
            detail: item.detail,
            reason: item.reason,
            action: item.action,
            project: item.project,
            urgency: item.urgency,
            symbol: item.symbol,
            state: item.state,
            disposition: disposition,
            score: item.score,
            evidence: item.evidence,
            query: item.query,
            path: item.path
        )
    }

    private func rankRadarItems(_ items: [RadarItem]) -> [RadarItem] {
        items
            .map { item -> RadarItem in
                let scored = radarScore(for: item)
                return withRadarScore(item, score: scored.score, evidence: scored.evidence)
            }
            .sorted {
                if $0.score == $1.score {
                    return $0.title < $1.title
                }
                return $0.score > $1.score
            }
    }

    private func withRadarScore(_ item: RadarItem, score: Int, evidence: [String]) -> RadarItem {
        RadarItem(
            id: item.id,
            title: item.title,
            detail: item.detail,
            reason: item.reason,
            action: item.action,
            project: item.project,
            urgency: item.urgency,
            symbol: item.symbol,
            state: item.state,
            disposition: item.disposition,
            score: score,
            evidence: evidence,
            query: item.query,
            path: item.path
        )
    }

    private func radarScore(for item: RadarItem) -> (score: Int, evidence: [String]) {
        var score = 0
        var evidence: [String] = []

        switch item.urgency {
        case "Now":
            score += 50
            evidence.append("Immediate execution")
        case "Safety":
            score += 45
            evidence.append("Reliability or permission risk")
        case "Triage":
            score += 38
            evidence.append("Needs classification")
        case "Review":
            score += 34
            evidence.append("Stale or unresolved")
        case "Next":
            score += 28
            evidence.append("Project movement")
        case "Explore":
            score += 18
            evidence.append("Idea or opportunity")
        case "Context":
            score += 14
            evidence.append("Fresh working material")
        default:
            score += 10
        }

        if item.state == .busy {
            score += 16
            evidence.append("Already delegated")
        } else if item.state == .warn {
            score += 12
            evidence.append("Attention state")
        }
        if item.disposition == .watching {
            score += 10
            evidence.append("You marked it watching")
        }
        if item.project != "General Brain" && item.project != "System" {
            score += 6
            evidence.append("Attached to \(item.project)")
        }
        if item.path != nil {
            score += 4
            evidence.append("Has source artifact")
        }
        if item.title.localizedCaseInsensitiveContains("Delegated") {
            score += 12
        }
        if item.title.localizedCaseInsensitiveContains("Stale") {
            score += 8
        }

        return (min(score, 100), Array(evidence.prefix(5)))
    }

    private func radarDispositionRecords() -> [String: [String: String]] {
        UserDefaults.standard.dictionary(forKey: "terminalBrainRadarDispositionRecords") as? [String: [String: String]] ?? [:]
    }

    private func saveRadarDispositionRecords(_ records: [String: [String: String]]) {
        UserDefaults.standard.set(records, forKey: "terminalBrainRadarDispositionRecords")
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
            let id = ensure(commit.project)
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

    private func titleForIdea(_ content: String) -> String {
        let firstLine = content
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !firstLine.isEmpty else { return "Captured Idea" }
        if firstLine.count <= 72 { return firstLine }
        let end = firstLine.index(firstLine.startIndex, offsetBy: 72)
        return "\(firstLine[..<end])..."
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
                let project = (parsed.frontmatter["project"] ?? "").ifEmpty(projectName(from: "\(title) \(parsed.question) \(parsed.preview) \(tags.joined(separator: " "))"))
                return OracleCommit(
                    id: url.path,
                    title: title,
                    question: parsed.question,
                    preview: parsed.preview,
                    status: status,
                    project: project,
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
