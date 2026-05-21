import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: BrainStatusModel
    @EnvironmentObject private var settings: AppSettings
    @State private var selectedSection = "use-now"
    @State private var selectedFeedID = ""
    @State private var selectedCommitID = ""
    @State private var selectedRadarID = ""
    @State private var selectedBlindspotID = ""
    @State private var selectedIdeaID = ""
    @State private var selectedProjectID = ""
    @State private var reviewProjectFilter = "all"
    @State private var feedFilter: FeedKind = .all
    @State private var selectedSourceID = "obsidian"
    @State private var memoryLeadIndex = 1
    @State private var recentWorkIndex = 1
    @State private var showCommandPalette = false
    @State private var commandQuery = ""

    private let columns = [
        GridItem(.adaptive(minimum: 260), spacing: 14)
    ]

    private var selectedFeedItem: BrainFeedItem? {
        filteredFeedItems.first { $0.id == selectedFeedID } ?? filteredFeedItems.first ?? model.feedItems.first
    }

    private var filteredFeedItems: [BrainFeedItem] {
        guard feedFilter != .all else { return model.feedItems }
        return model.feedItems.filter { $0.kind == feedFilter }
    }

    private var selectedSource: BrainSource? {
        model.sources.first { $0.id == selectedSourceID } ?? model.sources.first
    }

    private var selectedOracleCommit: OracleCommit? {
        filteredOracleCommits.first { $0.id == selectedCommitID } ?? filteredOracleCommits.first ?? model.oracleCommits.first
    }

    private var selectedRadarItem: RadarItem? {
        model.radarItems.first { $0.id == selectedRadarID } ?? model.radarItems.first
    }

    private var selectedBlindspotItem: BlindspotItem? {
        model.blindspotItems.first { $0.id == selectedBlindspotID } ?? model.blindspotItems.first
    }

    private var selectedIdeaItem: IdeaPulseItem? {
        model.ideaPulseItems.first { $0.id == selectedIdeaID } ?? model.ideaPulseItems.first
    }

    private var selectedProject: ProjectMemory? {
        model.projects.first { $0.id == selectedProjectID } ?? model.projects.first
    }

    private var filteredOracleCommits: [OracleCommit] {
        guard reviewProjectFilter != "all" else { return model.oracleCommits }
        return model.oracleCommits.filter { $0.project == reviewProjectFilter }
    }

    private var commandItems: [BrainCommand] {
        var items: [BrainCommand] = [
            BrainCommand(title: "Open Use Now", subtitle: "Read, ask, capture, delegate, and close the loop", symbol: "bolt.circle.fill", category: "Navigate", action: .section("use-now")),
            BrainCommand(title: "Open Work Block", subtitle: "Pull forward, triage, and close the loop", symbol: "target", category: "Navigate", action: .section("work-block")),
            BrainCommand(title: "Open First Minute", subtitle: "Shortest value path, next step, and working proof", symbol: "1.circle.fill", category: "Navigate", action: .section("first-minute")),
            BrainCommand(title: "Open Demo", subtitle: "Temporary seeded walkthrough of the value loop", symbol: "play.rectangle.fill", category: "Navigate", action: .section("demo")),
            BrainCommand(title: "Open Playbook", subtitle: "Which command to run for common situations", symbol: "book.closed.fill", category: "Navigate", action: .section("playbook")),
            BrainCommand(title: "Open Value Audit", subtitle: "Evidence map for first-use value and remaining gaps", symbol: "checkmark.seal.fill", category: "Navigate", action: .section("value-audit")),
            BrainCommand(title: "Open Now", subtitle: "Bottom line, next action, process truth, and outcome loop", symbol: "sparkles", category: "Navigate", action: .section("now")),
            BrainCommand(title: "Open Value Now", subtitle: "Plain-language value read and fastest useful path", symbol: "bolt.fill", category: "Navigate", action: .section("value")),
            BrainCommand(title: "Open Start Here", subtitle: "One block, one artifact, one written outcome", symbol: "play.circle.fill", category: "Navigate", action: .section("start-here")),
            BrainCommand(title: "Ask Current Focus", subtitle: model.focusItem.title, symbol: "sparkle.magnifyingglass", category: "Action", action: .askFocus),
            BrainCommand(title: "Open Focus", subtitle: "One recommended action from Radar and Today", symbol: "target", category: "Navigate", action: .section("focus")),
            BrainCommand(title: "Open Cockpit", subtitle: "Local gateway, source health, and Mission reachability", symbol: "house.fill", category: "Navigate", action: .section("cockpit")),
            BrainCommand(title: "Open Setup", subtitle: "Readiness checklist for app, MCP, sources, and sync", symbol: "checklist.checked", category: "Navigate", action: .section("setup")),
            BrainCommand(title: "Open Radar", subtitle: "Proactive signals, stale reads, risks, and opportunities", symbol: "scope", category: "Navigate", action: .section("radar")),
            BrainCommand(title: "Open Blindspots", subtitle: "Ignored, stale, under-tested, or unresolved work", symbol: "eye.fill", category: "Navigate", action: .section("blindspots")),
            BrainCommand(title: "Open Ideas", subtitle: "Captured thoughts, bubbling opportunities, and cheap tests", symbol: "lightbulb.fill", category: "Navigate", action: .section("ideas")),
            BrainCommand(title: "Open Feed", subtitle: "Recent context packs, sync events, and source alerts", symbol: "list.bullet.rectangle.portrait.fill", category: "Navigate", action: .section("feed")),
            BrainCommand(title: "Open Oracle", subtitle: "Narrative brief, bubbling ideas, and open loops", symbol: "sparkle.magnifyingglass", category: "Navigate", action: .section("oracle")),
            BrainCommand(title: "Open Review Queue", subtitle: "Committed Oracle reads, decisions, and follow-ups", symbol: "tray.and.arrow.down.fill", category: "Navigate", action: .section("review")),
            BrainCommand(title: "Open Projects", subtitle: "Project memory pages and active work surfaces", symbol: "folder.fill.badge.gearshape", category: "Navigate", action: .section("projects")),
            BrainCommand(title: "Open Memory", subtitle: "Derived Codex/Claude continuity leads and promotion prompts", symbol: "brain.head.profile", category: "Navigate", action: .section("memory")),
            BrainCommand(title: "Open Today", subtitle: "Deterministic daily briefing", symbol: "sun.max.fill", category: "Navigate", action: .section("briefing")),
            BrainCommand(title: "Open Sources", subtitle: "Permissioned capture, memory, and compute surfaces", symbol: "tray.full.fill", category: "Navigate", action: .section("sources")),
            BrainCommand(title: "Open System", subtitle: "Native macOS surfaces and integration roadmap", symbol: "puzzlepiece.extension.fill", category: "Navigate", action: .section("system")),
            BrainCommand(title: "Run Sync", subtitle: "Refresh edge brain export with current permission policy", symbol: "arrow.triangle.2.circlepath", category: "Action", action: .runSync),
            BrainCommand(title: "Copy Operator Snapshot", subtitle: "Prompt-ready Focus, Radar, actions, and memory trail", symbol: "doc.on.clipboard", category: "Action", action: .copySnapshot),
            BrainCommand(title: "Copy First Minute", subtitle: "Shortest explanation, next step, and working proof", symbol: "1.circle.fill", category: "Action", action: .copyFirstMinute),
            BrainCommand(title: "Copy Demo", subtitle: "Seeded temporary walkthrough", symbol: "play.rectangle.fill", category: "Action", action: .copyDemo),
            BrainCommand(title: "Copy Playbook", subtitle: "Operator command map and daily cadence", symbol: "book.closed.fill", category: "Action", action: .copyPlaybook),
            BrainCommand(title: "Copy Value Audit", subtitle: "Evidence checklist and gaps", symbol: "checkmark.seal.fill", category: "Action", action: .copyValueAudit),
            BrainCommand(title: "Copy Now", subtitle: "Bottom line, next action, process truth, and close loop", symbol: "sparkles", category: "Action", action: .copyNow),
            BrainCommand(title: "Copy Process Map", subtitle: "Terminal Brain, Codex, MCP, kernel, Drafts, launchctl, and API state", symbol: "point.3.connected.trianglepath.dotted", category: "Action", action: .copyProcessMap),
            BrainCommand(title: "Copy Cleanup Plan", subtitle: "Read-only stale MCP/kernel process cleanup guidance", symbol: "wrench.and.screwdriver.fill", category: "Action", action: .copyCleanupPlan),
            BrainCommand(title: "Copy Support Bundle", subtitle: "Now, Work Block, Doctor, Audit, Process Map, Cleanup Plan, and Git state", symbol: "shippingbox.and.arrow.backward.fill", category: "Action", action: .copySupportBundle),
            BrainCommand(title: "Copy Use Now", subtitle: "One-page read, ask, capture, delegate, and outcome path", symbol: "bolt.circle.fill", category: "Action", action: .copyUseNow),
            BrainCommand(title: "Copy Work Block", subtitle: "Pull forward, triage, and close the loop", symbol: "target", category: "Action", action: .copyWorkBlock),
            BrainCommand(title: "Copy Start Here", subtitle: "One block, one artifact, one written outcome", symbol: "play.circle.fill", category: "Action", action: .copyStartHere),
            BrainCommand(title: "Copy Value Brief", subtitle: "Compact read on why the current move is worth attention", symbol: "bolt.fill", category: "Action", action: .copyValueBrief),
            BrainCommand(title: "Copy Oracle Brief", subtitle: "Direct read, next moves, missing signal, cheap test, and agent handoff", symbol: "wand.and.stars", category: "Action", action: .copyOracleBrief),
            BrainCommand(title: "Copy Oracle Digest", subtitle: "Notice, decide, test, create, and avoid lanes", symbol: "sparkle.magnifyingglass", category: "Action", action: .copyOracleDigest),
            BrainCommand(title: "Copy Operator Brief", subtitle: "Plain-language value read", symbol: "wand.and.stars", category: "Action", action: .copyBrief),
            BrainCommand(title: "Copy Decision Lane", subtitle: "Ranked Today action queue", symbol: "list.number", category: "Action", action: .copyDecisionLane),
            BrainCommand(title: "Copy Blindspot Brief", subtitle: "Counter-signal before broad planning", symbol: "eye.fill", category: "Action", action: .copyBlindspots),
            BrainCommand(title: "Copy Idea Pulse", subtitle: "Cheap-test queue for captured ideas", symbol: "lightbulb.fill", category: "Action", action: .copyIdeas),
            BrainCommand(title: "Copy Project Memory", subtitle: "Active work surfaces and recommended actions", symbol: "folder.fill.badge.gearshape", category: "Action", action: .copyProjectMemory),
            BrainCommand(title: "Copy Source Inventory", subtitle: "Visible local sources and raw-transcript policy", symbol: "tray.full.fill", category: "Action", action: .copySourceInventory),
            BrainCommand(title: "Copy Memory Brief", subtitle: "Derived Codex/Claude continuity leads", symbol: "brain.head.profile", category: "Action", action: .copyMemoryBrief),
            BrainCommand(title: "Promote Recent Work", subtitle: "Turn the newest git change into reviewable Oracle memory", symbol: "arrow.up.doc.fill", category: "Action", action: .promoteRecentWork),
            BrainCommand(title: "Copy Operator Deck", subtitle: "Prompt-ready four-card deck for handoffs", symbol: "rectangle.stack.fill.badge.person.crop", category: "Action", action: .copyDeck),
            BrainCommand(title: "Copy Agent Prompt", subtitle: "Focused execution prompt for Codex or Claude", symbol: "paperplane.fill", category: "Action", action: .copyAgentPrompt),
            BrainCommand(title: "Copy Latest Context Pack", subtitle: "Copy newest context pack Markdown", symbol: "doc.on.doc", category: "Action", action: .copyLatestPack),
            BrainCommand(title: "Copy Agent Handoff", subtitle: "Copy Operator Deck plus latest context pack", symbol: "doc.richtext", category: "Action", action: .copyHandoff),
            BrainCommand(title: "Open Mission Control", subtitle: Paths.missionURL.absoluteString, symbol: "display", category: "Action", action: .openMission),
            BrainCommand(title: "Open Logs", subtitle: Paths.syncLog, symbol: "doc.text", category: "Action", action: .openLogs),
            BrainCommand(title: "Open Workspace", subtitle: Paths.workspace, symbol: "folder", category: "Action", action: .openWorkspace)
        ]

        let trimmedQuery = commandQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let contextQuery = inferredContextQuery()
        if !trimmedQuery.isEmpty {
            items.insert(
                BrainCommand(
                    title: "Ask Oracle",
                    subtitle: trimmedQuery,
                    symbol: "sparkle.magnifyingglass",
                    category: "Ask",
                    action: .askOracle(trimmedQuery)
                ),
                at: 0
            )
            items.insert(
                BrainCommand(
                    title: "Capture Idea",
                    subtitle: trimmedQuery,
                    symbol: "lightbulb",
                    category: "Capture",
                    action: .draftIdea(trimmedQuery)
                ),
                at: 1
            )
        }

        if !contextQuery.isEmpty {
            items.insert(
                BrainCommand(
                    title: "Build context pack",
                    subtitle: contextQuery,
                    symbol: "shippingbox.fill",
                    category: "Start Work",
                    action: .buildContext(contextQuery)
                ),
                at: trimmedQuery.isEmpty ? 0 : 2
            )
        } else {
            items.append(
                BrainCommand(title: "Start Work", subtitle: "Prepare a context pack before handing work to an agent", symbol: "sparkles", category: "Navigate", action: .section("start"))
            )
        }

        items.append(contentsOf: model.sources.map { source in
            BrainCommand(title: source.name, subtitle: "\(source.mode) - \(source.status)", symbol: source.symbol, category: "Source", action: .source(source.id))
        })

        items.append(contentsOf: model.feedItems.map { item in
            BrainCommand(title: item.title, subtitle: "\(item.kind.label) - \(item.subtitle)", symbol: item.symbol, category: "Feed", action: .feed(item.id, item.kind))
        })

        items.append(contentsOf: model.oracleCommits.map { commit in
            BrainCommand(title: commit.title, subtitle: "\(commit.status.label) - \(commit.preview)", symbol: commit.status.symbol, category: "Review", action: .commit(commit.id))
        })

        items.append(contentsOf: model.radarItems.map { item in
            BrainCommand(title: item.title, subtitle: "\(item.urgency) - \(item.detail)", symbol: item.symbol, category: "Radar", action: .radar(item.id))
        })

        items.append(contentsOf: model.blindspotItems.map { item in
            BrainCommand(title: item.title, subtitle: "\(item.score) - \(item.question)", symbol: item.symbol, category: "Blindspot", action: .blindspot(item.id))
        })

        items.append(contentsOf: model.ideaPulseItems.map { item in
            BrainCommand(title: item.title, subtitle: "\(item.score) - \(item.nextPrompt)", symbol: item.symbol, category: "Idea", action: .idea(item.id))
        })

        items.append(contentsOf: model.projects.map { project in
            BrainCommand(title: project.name, subtitle: project.summary, symbol: project.symbol, category: "Project", action: .project(project.id))
        })

        items.append(contentsOf: model.briefing.map { item in
            BrainCommand(title: item.title, subtitle: item.detail, symbol: item.symbol, category: "Briefing", action: .section("briefing"))
        })

        let query = commandQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return items }
        return items.filter { item in
            "\(item.title) \(item.subtitle) \(item.category)".lowercased().contains(query)
        }
    }

    private var sectionTitle: String {
        switch selectedSection {
        case "use-now": return "Use Now"
        case "work-block": return "Work Block"
        case "first-minute": return "First Minute"
        case "demo": return "Demo"
        case "playbook": return "Playbook"
        case "value-audit": return "Value Audit"
        case "now": return "Now"
        case "value": return "Value Now"
        case "start-here": return "Start Here"
        case "focus": return "Focus"
        case "setup": return "Setup"
        case "radar": return "Radar"
        case "blindspots": return "Blindspots"
        case "ideas": return "Ideas"
        case "feed": return "Feed"
        case "oracle": return "Oracle"
        case "review": return "Review"
        case "projects": return "Projects"
        case "memory": return "Memory"
        case "sources": return "Sources"
        case "briefing": return "Today"
        case "start": return "Start Work"
        case "system": return "System"
        default: return "Cockpit"
        }
    }

    private var sectionSubtitle: String {
        switch selectedSection {
        case "use-now": return "One page to read the signal, ask what is missing, capture a thought, delegate work, and write back the outcome."
        case "work-block": return "Pull forward the strongest signal, triage it, do the smallest useful work, and write back the outcome."
        case "first-minute": return "The shortest path to value: what this is, what to do, and proof the loop works."
        case "demo": return "Seed a temporary workspace and watch ideas become review, Bubble Up, Work Block, and outcome commands."
        case "playbook": return "A plain operator map for capture, Oracle reads, agent handoff, outcomes, and runtime checks."
        case "value-audit": return "Evidence that first-use value is covered, plus the remaining gaps before native UI certification."
        case "now": return "Bottom line, next action, process truth, readiness, and close loop."
        case "value": return "What this is worth right now, what to do next, and what artifact to create."
        case "start-here": return "One block, one artifact, one written outcome."
        case "focus": return "One recommended move, why it matters, and the fastest next action."
        case "setup": return "Readiness checklist for the app, MCP gateway, memory, sync, and permission posture."
        case "radar": return "Proactive signals, stale reads, quiet risks, and opportunities worth a decision."
        case "blindspots": return "The counter-signal lane for ignored, stale, under-tested, or unresolved work."
        case "ideas": return "Captured thoughts and resurfaced opportunities ranked by what deserves a cheap test."
        case "feed": return "Recent context packs, sync events, and source alerts."
        case "oracle": return "Narrative signals, open loops, and ideas worth revisiting."
        case "review": return "Committed Oracle reads that need acceptance, linking, delegation, or dismissal."
        case "projects": return "Durable project memory pages assembled from context packs and Oracle commits."
        case "memory": return "Derived Codex and Claude continuity leads with safe promotion commands."
        case "sources": return "Permissioned capture, memory, and compute surfaces."
        case "briefing": return "A deterministic briefing from local memory and Mission Control."
        case "start": return "Build a context pack before handing work to an agent."
        case "system": return "Native macOS surfaces and integration roadmap."
        default: return "Local gateway, source health, sync state, and Mission reachability."
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 250, ideal: 288, max: 340)
        } detail: {
            detailSurface
        }
        .background(Color.clear.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {} label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(true)
                .help("Back")
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    commandQuery = ""
                    showCommandPalette = true
                } label: {
                    Label("Find", systemImage: "magnifyingglass")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white.opacity(0.56))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .frame(width: 180, alignment: .leading)
                        .background(.white.opacity(0.08), in: Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut("k", modifiers: [.command])
                .help("Search commands")

                StatusPill(text: model.summaryLine, state: model.summaryLine == "Brain status ready" ? .good : .warn)

                Button {
                    Task { await model.refresh() }
                } label: {
                    Label(model.isRefreshing ? "Checking" : "Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(model.isRefreshing)

                Button {
                    Task { await model.runSyncNow() }
                } label: {
                    Label(model.isSyncing ? "Syncing" : "Run Sync", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(model.isSyncing)
                .buttonStyle(.borderedProminent)

                toolbarProfileMenu
            }
        }
        .navigationTitle("")
        .overlay {
            if showCommandPalette {
                CommandPaletteView(
                    query: $commandQuery,
                    items: commandItems,
                    accent: settings.theme.accent,
                    onCancel: { showCommandPalette = false },
                    onSelect: { applyCommand($0) }
                )
            }
        }
        .background(WindowConfigurator().frame(width: 0, height: 0))
    }

    private var sidebar: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(settings.theme.accent)
                        .frame(width: 28, height: 28)
                        .background(.white.opacity(0.08), in: Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Terminal Brain")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Local operator")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.56))
                    }
                }

                Button {
                    commandQuery = ""
                    showCommandPalette = true
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Home")
                    .sidebarHeader()
                NavRow(title: "Use Now", symbol: "bolt.circle.fill", badge: "", selected: selectedSection == "use-now") { selectedSection = "use-now" }
                NavRow(title: "Work Block", symbol: "target", badge: "\(model.oracleCommits.filter { $0.status == .new || $0.status == .delegated }.count)", selected: selectedSection == "work-block") { selectedSection = "work-block" }
                NavRow(title: "Now", symbol: "sparkles", badge: model.setupAttentionCount == 0 ? "" : "\(model.setupAttentionCount)", selected: selectedSection == "now") { selectedSection = "now" }
                NavRow(title: "Value", symbol: "bolt.fill", badge: "\(model.focusItem.score)", selected: selectedSection == "value") { selectedSection = "value" }
                NavRow(title: "Start Here", symbol: "play.circle.fill", badge: "", selected: selectedSection == "start-here") { selectedSection = "start-here" }
                NavRow(title: "Focus", symbol: "target", badge: "\(model.focusItem.score)", selected: selectedSection == "focus") { selectedSection = "focus" }
                NavRow(title: "Cockpit", symbol: "house.fill", badge: model.summaryLine == "Brain status ready" ? "" : "!", selected: selectedSection == "cockpit") { selectedSection = "cockpit" }
                NavRow(title: "Setup", symbol: "checklist.checked", badge: model.setupAttentionCount == 0 ? "" : "\(model.setupAttentionCount)", selected: selectedSection == "setup") { selectedSection = "setup" }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Learn")
                    .sidebarHeader()
                NavRow(title: "First Minute", symbol: "1.circle.fill", badge: "", selected: selectedSection == "first-minute") { selectedSection = "first-minute" }
                NavRow(title: "Demo", symbol: "play.rectangle.fill", badge: "", selected: selectedSection == "demo") { selectedSection = "demo" }
                NavRow(title: "Playbook", symbol: "book.closed.fill", badge: "", selected: selectedSection == "playbook") { selectedSection = "playbook" }
                NavRow(title: "Value Audit", symbol: "checkmark.seal.fill", badge: "", selected: selectedSection == "value-audit") { selectedSection = "value-audit" }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Signals")
                    .sidebarHeader()
                NavRow(title: "Radar", symbol: "scope", badge: "\(model.radarItems.count)", selected: selectedSection == "radar") { selectedSection = "radar" }
                NavRow(title: "Blindspots", symbol: "eye.fill", badge: "\(model.blindspotItems.count)", selected: selectedSection == "blindspots") { selectedSection = "blindspots" }
                NavRow(title: "Ideas", symbol: "lightbulb.fill", badge: "\(model.ideaPulseItems.count)", selected: selectedSection == "ideas") { selectedSection = "ideas" }
                NavRow(title: "Oracle", symbol: "sparkle.magnifyingglass", badge: "\(model.oracleItems.count)", selected: selectedSection == "oracle") { selectedSection = "oracle" }
                NavRow(title: "Review", symbol: "tray.and.arrow.down.fill", badge: "\(model.oracleCommits.filter { $0.status == .new }.count)", selected: selectedSection == "review") { selectedSection = "review" }
                NavRow(title: "Projects", symbol: "folder.fill.badge.gearshape", badge: "\(model.projects.count)", selected: selectedSection == "projects") { selectedSection = "projects" }
                NavRow(title: "Memory", symbol: "brain.head.profile", badge: "", selected: selectedSection == "memory") { selectedSection = "memory" }
                NavRow(title: "Feed", symbol: "list.bullet.rectangle.portrait.fill", badge: "\(model.feedItems.count)", selected: selectedSection == "feed") { selectedSection = "feed" }
                NavRow(title: "Today", symbol: "sun.max.fill", badge: "\(model.briefing.count)", selected: selectedSection == "briefing") { selectedSection = "briefing" }
                NavRow(title: "Start Work", symbol: "sparkles", badge: "", selected: selectedSection == "start") { selectedSection = "start" }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Library")
                    .sidebarHeader()
                NavRow(title: "Sources", symbol: "tray.full.fill", badge: "\(model.sources.count)", selected: selectedSection == "sources") { selectedSection = "sources" }
                NavRow(title: "System", symbol: "puzzlepiece.extension.fill", badge: systemBadge, selected: selectedSection == "system") { selectedSection = "system" }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 9) {
                MiniStatus(label: "API", value: "8765", symbol: "network")
                MiniStatus(label: "MCP", value: mcpMiniStatus, symbol: "antenna.radiowaves.left.and.right")
                MiniStatus(label: "Safety", value: safetyMiniStatus, symbol: "lock.shield.fill")
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            profileMenu
        }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 12)
        }
        .background(.clear)
    }

    private var systemBadge: String {
        let attention = model.cards.filter { $0.state == .warn }.count
        return attention == 0 ? "" : "\(attention)"
    }

    private var mcpMiniStatus: String {
        guard let card = healthCard(named: "Local Brain MCP") else { return "Unknown" }
        return card.state == .good ? "Running" : "Needs check"
    }

    private var safetyMiniStatus: String {
        let promptRisk = ["Apple Notes MCP", "Drafts MCP", "Hourly Sync Agent"]
            .compactMap { healthCard(named: $0) }
            .contains { $0.state == .warn }
        return promptRisk ? "Review" : "Quiet"
    }

    private var profileMenu: some View {
        Menu {
            Section("Profile") {
                Label("John Christensen", systemImage: "person.crop.circle")
                Label("Local Operator", systemImage: "shield.lefthalf.filled")
            }
            Divider()
            Picker("Theme", selection: $settings.theme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.label).tag(theme)
                }
            }
            Toggle("Reduce Glass", isOn: $settings.reduceGlass)
            Toggle("Advanced System Surfaces", isOn: $settings.showAdvancedSystem)
            Divider()
            SettingsLink { Label("Settings", systemImage: "gearshape") }
            Button { model.openLogs() } label: { Label("Open Logs", systemImage: "doc.text") }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title3)
                    .foregroundStyle(settings.theme.accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text("John Christensen")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Settings & themes")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.48))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .menuStyle(.button)
    }

    private var toolbarProfileMenu: some View {
        Menu {
            Section("Profile") {
                Label("John Christensen", systemImage: "person.crop.circle")
                Label("Local Operator", systemImage: "shield.lefthalf.filled")
            }
            Divider()
            Picker("Theme", selection: $settings.theme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.label).tag(theme)
                }
            }
            Toggle("Reduce Glass", isOn: $settings.reduceGlass)
            Divider()
            SettingsLink { Label("Settings", systemImage: "gearshape") }
            Button { model.openLogs() } label: { Label("Open Logs", systemImage: "doc.text") }
        } label: {
            Image(systemName: "person.crop.circle.fill")
        }
        .help("Profile and settings")
    }

    private var detailSurface: some View {
        VStack(spacing: 0) {
            detailHeader
            Divider().overlay(.white.opacity(0.08))
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch selectedSection {
                    case "use-now": useNowView
                    case "work-block": workBlockView
                    case "first-minute": firstMinuteView
                    case "demo": demoView
                    case "playbook": playbookView
                    case "value-audit": valueAuditView
                    case "now": nowView
                    case "value": valueNowView
                    case "start-here": startHereView
                    case "focus": focusView
                    case "setup": setupView
                    case "radar": radarView
                    case "blindspots": blindspotsView
                    case "ideas": ideasView
                    case "oracle": oracleView
                    case "review": reviewView
                    case "projects": projectsView
                    case "memory": memoryBriefView
                    case "feed": feedView
                    case "sources": sourcesView
                    case "briefing": briefingView
                    case "start": startWorkView
                    case "system": systemView
                    default: cockpitView
                    }
                }
                .padding(20)
            }
        }
        .background(
            LinearGradient(colors: settings.theme.background, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
    }

    private var useNowView: some View {
        let focus = model.focusItem
        let topReview = model.oracleCommits.first { $0.status == .new || $0.status == .delegated }
        let project = focus.project.isEmpty ? "Terminal Brain" : focus.project
        let useNowTitle = topReview?.title ?? focus.title
        let useNowReason: String
        if topReview == nil {
            useNowReason = focus.reason
        } else {
            useNowReason = "This is the top open review signal. Accept, delegate, link, or dismiss it so it stops floating."
        }

        return VStack(alignment: .leading, spacing: 18) {
            valueSurfaceHero(
                eyebrow: "Use Now",
                title: "Start with one move.",
                detail: "Use this when you want the next action, not another dashboard: act on the signal, ask if needed, then write back the outcome.",
                symbol: "bolt.circle.fill",
                primaryTitle: "Copy Use Now",
                primarySymbol: "bolt.circle.fill",
                primaryAction: { Task { await model.copyUseNow() } },
                secondaryTitle: "Ask Oracle",
                secondarySymbol: "sparkle.magnifyingglass",
                secondaryAction: {
                    model.oracleQuestion = "What should I do next for \(project), and what am I missing?"
                    selectedSection = "oracle"
                },
                output: model.useNowCopyOutput
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                ValueBriefTile(
                    label: "One Move",
                    title: useNowTitle,
                    detail: topReview?.preview ?? "Do this first: \(focus.reason)",
                    action: topReview == nil ? focus.action : "Open Review",
                    symbol: topReview?.status.symbol ?? focus.symbol,
                    accent: topReview?.status.color ?? focus.state.color
                ) {
                    if let topReview {
                        selectedCommitID = topReview.id
                        reviewProjectFilter = topReview.project.isEmpty ? "all" : topReview.project
                        selectedSection = "review"
                    } else {
                        applyFocusAction(focus)
                    }
                }

                ValueBriefTile(
                    label: "Why",
                    title: "Why this move",
                    detail: useNowReason,
                    action: "Challenge It",
                    symbol: "questionmark.circle.fill",
                    accent: .cyan
                ) {
                    model.oracleQuestion = "Why is \(useNowTitle) the right next move for \(project), and what could make it wrong?"
                    selectedSection = "oracle"
                }

                ValueBriefTile(
                    label: "Ask",
                    title: "What am I missing?",
                    detail: "Turn ambiguity into one direct Oracle read instead of scanning more surfaces.",
                    action: "Ask Oracle",
                    symbol: "sparkle.magnifyingglass",
                    accent: settings.theme.accent
                ) {
                    model.oracleQuestion = "What should I do next for \(project), and what am I missing?"
                    selectedSection = "oracle"
                }

                ValueBriefTile(
                    label: "Capture",
                    title: "Pressure point",
                    detail: "If the next signal is still in your head, save it before it disappears.",
                    action: "Capture",
                    symbol: "lightbulb.fill",
                    accent: .yellow
                ) {
                    model.quickIdea = "The thing I keep circling is ..."
                    selectedSection = "focus"
                }

                ValueBriefTile(
                    label: "Delegate",
                    title: "Agent Prompt",
                    detail: "Copy a bounded Codex or Claude prompt with guardrails and close-loop instructions.",
                    action: "Copy Prompt",
                    symbol: "paperplane.fill",
                    accent: .blue
                ) {
                    Task { await model.copyAgentPrompt() }
                }

                ValueBriefTile(
                    label: "Close",
                    title: "Outcome writeback",
                    detail: "Write what changed, why it mattered, evidence, and next action into durable memory.",
                    action: "Commit Outcome",
                    symbol: "square.and.arrow.down.fill",
                    accent: .green
                ) {
                    model.outcomeTitle = focus.title
                    model.outcomeNextAction = "Run Use Now again and pick the next useful signal."
                    selectedSection = "start-here"
                }
            }

            focusIdeaCapturePanel(focus)
            startHereOutcomePanel(project: project)
        }
    }

    private var detailHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(sectionTitle)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(sectionSubtitle)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.58))
            }
            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(.black.opacity(0.10))
    }

    private var cockpitView: some View {
        VStack(alignment: .leading, spacing: 18) {
            heroPanel
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    SectionTitle("Source Health", symbol: "waveform.path.ecg")
                    VStack(spacing: 0) {
                        ForEach(model.cards) { card in
                            HealthRow(card: card)
                            if card.id != model.cards.last?.id {
                                Divider().overlay(.white.opacity(0.08)).padding(.leading, 48)
                            }
                        }
                    }
                    .darkPanel()
                }
                .frame(minWidth: 520)

                VStack(alignment: .leading, spacing: 14) {
                    SectionTitle("Operator Notes", symbol: "checklist")
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(model.findings, id: \.self) { finding in
                            Label(finding, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.78))
                                .font(.callout)
                        }
                    }
                    .padding(12)
                    .darkPanel()

                    sourceControls
                }
                .frame(width: 420)
            }
            syncOutput
        }
    }

    private var workBlockView: some View {
        let focus = model.focusItem
        let openReviews = model.oracleCommits.filter { $0.status == .new || $0.status == .delegated }
        let topReview = openReviews.first
        let openReviewCount = openReviews.count
        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "target")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(settings.theme.accent)
                        .frame(width: 58, height: 58)
                        .background(settings.theme.accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Work Block")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(settings.theme.accent)
                            .textCase(.uppercase)
                        Text(topReview.map { "Triage \($0.title)" } ?? "Pull one signal forward.")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                        Text("Triage it, do the smallest useful work, and commit the outcome.")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()
                    StatusPill(text: openReviewCount == 0 ? "Clear" : "\(openReviewCount) open", state: openReviewCount == 0 ? .good : .warn)
                }

                HStack(spacing: 8) {
                    Button { Task { await model.copyWorkBlock() } } label: {
                        Label("Copy Work Block", systemImage: "target")
                    }
                    .buttonStyle(.borderedProminent)

                    Button { Task { await model.copyAgentPrompt() } } label: {
                        Label("Agent Prompt", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        reviewProjectFilter = focus.project.isEmpty ? "all" : focus.project
                        if let topReview {
                            selectedCommitID = topReview.id
                            reviewProjectFilter = topReview.project.isEmpty ? "all" : topReview.project
                        }
                        selectedSection = "review"
                    } label: {
                        Label("Review Queue", systemImage: "tray.and.arrow.down.fill")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        model.workQuery = focus.query.isEmpty ? focus.title : focus.query
                        selectedSection = "start"
                    } label: {
                        Label("Start Work", systemImage: "shippingbox.fill")
                    }
                    .buttonStyle(.bordered)
                }

                if !model.workBlockCopyOutput.isEmpty || !model.agentPromptCopyOutput.isEmpty {
                    Text(!model.workBlockCopyOutput.isEmpty ? model.workBlockCopyOutput : model.agentPromptCopyOutput)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
            .padding(20)
            .darkPanel()

            if let topReview {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle("Top Review Action", symbol: topReview.status.symbol)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(topReview.title)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                Text(topReview.preview)
                                    .font(.callout)
                                    .foregroundStyle(.white.opacity(0.62))
                                    .lineLimit(3)
                            }
                            Spacer()
                            StatusPill(text: topReview.status.label, state: topReview.status == .new || topReview.status == .delegated ? .warn : .good)
                        }

                        HStack(spacing: 8) {
                            Button {
                                model.setOracleCommitStatus(topReview, status: .accepted)
                            } label: {
                                Label("Accept", systemImage: "checkmark.seal")
                            }
                            Button {
                                model.delegateOracleCommitToStartWork(topReview)
                                selectedSection = "start"
                            } label: {
                                Label("Delegate", systemImage: "paperplane")
                            }
                            Button {
                                model.setOracleCommitStatus(topReview, status: .dismissed)
                            } label: {
                                Label("Dismiss", systemImage: "xmark.circle")
                            }
                            Button {
                                selectedCommitID = topReview.id
                                reviewProjectFilter = topReview.project.isEmpty ? "all" : topReview.project
                                selectedSection = "review"
                            } label: {
                                Label("Open", systemImage: "tray.and.arrow.down")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(14)
                    .darkPanel()
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                ValueBriefTile(
                    label: "1. Pull Forward",
                    title: focus.title,
                    detail: focus.reason,
                    action: focus.action,
                    symbol: focus.symbol,
                    accent: focus.state.color
                ) {
                    applyFocusAction(focus)
                }

                ValueBriefTile(
                    label: "2. Triage",
                    title: topReview?.title ?? "Review queue is clear",
                    detail: topReview?.preview ?? "Accept, delegate, dismiss, or link Oracle Inbox items before they become background noise.",
                    action: "Open Review",
                    symbol: topReview?.status.symbol ?? "tray.and.arrow.down.fill",
                    accent: topReview?.status.color ?? .green
                ) {
                    if let topReview {
                        selectedCommitID = topReview.id
                        reviewProjectFilter = topReview.project.isEmpty ? "all" : topReview.project
                    }
                    selectedSection = "review"
                }

                ValueBriefTile(
                    label: "3. Do",
                    title: "Smallest useful work",
                    detail: "Build a context pack or hand a bounded prompt to an agent instead of scanning another dashboard.",
                    action: "Start Work",
                    symbol: "shippingbox.fill",
                    accent: .blue
                ) {
                    model.workQuery = focus.query.isEmpty ? focus.title : focus.query
                    selectedSection = "start"
                }

                ValueBriefTile(
                    label: "4. Remember",
                    title: "Outcome writeback",
                    detail: "Commit what changed, why it matters, evidence, and the next action to durable memory.",
                    action: "Commit Outcome",
                    symbol: "square.and.arrow.down.fill",
                    accent: .green
                ) {
                    model.outcomeTitle = focus.title
                    model.outcomeNextAction = "Review the next Work Block."
                    selectedSection = "start-here"
                }
            }

            focusIdeaCapturePanel(focus)
            valueBriefPanel
            startHereOutcomePanel(project: focus.project)
        }
    }

    private var firstMinuteView: some View {
        let focus = model.focusItem
        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "1.circle.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(settings.theme.accent)
                        .frame(width: 58, height: 58)
                        .background(settings.theme.accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("First Minute")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(settings.theme.accent)
                            .textCase(.uppercase)
                        Text("Get value without hunting through the app.")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                        Text("Read the next move, hand it to an agent, then write back the outcome.")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()
                    StatusPill(text: model.summaryLine, state: model.summaryLine == "Brain status ready" ? .good : .warn)
                }

                HStack(spacing: 8) {
                    Button { Task { await model.copyFirstMinute() } } label: {
                        Label("Copy First Minute", systemImage: "1.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button { Task { await model.copyAgentPrompt() } } label: {
                        Label("Agent Prompt", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(.bordered)

                    Button { Task { await model.copyWorkBlock() } } label: {
                        Label("Work Block", systemImage: "target")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        model.workQuery = focus.query.isEmpty ? focus.title : focus.query
                        selectedSection = "start"
                    } label: {
                        Label("Start Work", systemImage: "shippingbox.fill")
                    }
                    .buttonStyle(.bordered)

                    Button { Task { await model.copyValueProof() } } label: {
                        Label("Prove Value", systemImage: "checkmark.seal")
                    }
                    .buttonStyle(.bordered)
                }

                if !model.firstMinuteCopyOutput.isEmpty || !model.agentPromptCopyOutput.isEmpty || !model.workBlockCopyOutput.isEmpty || !model.valueProofCopyOutput.isEmpty {
                    Text(!model.firstMinuteCopyOutput.isEmpty ? model.firstMinuteCopyOutput : (!model.agentPromptCopyOutput.isEmpty ? model.agentPromptCopyOutput : (!model.workBlockCopyOutput.isEmpty ? model.workBlockCopyOutput : model.valueProofCopyOutput)))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
            .padding(20)
            .darkPanel()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                ValueBriefTile(
                    label: "1. Notice",
                    title: focus.title,
                    detail: focus.reason,
                    action: focus.action,
                    symbol: focus.symbol,
                    accent: focus.state.color
                ) {
                    applyFocusAction(focus)
                }

                ValueBriefTile(
                    label: "2. Hand off",
                    title: "Agent Prompt",
                    detail: "Copy a bounded execution prompt grounded in the current focus and guardrails.",
                    action: "Copy Prompt",
                    symbol: "paperplane.fill",
                    accent: settings.theme.accent
                ) {
                    Task { await model.copyAgentPrompt() }
                }

                ValueBriefTile(
                    label: "3. Create",
                    title: "Context Pack",
                    detail: "Build a local context pack before handing deeper work to Codex or Claude.",
                    action: "Start Work",
                    symbol: "shippingbox.fill",
                    accent: .blue
                ) {
                    model.workQuery = focus.query.isEmpty ? focus.title : focus.query
                    selectedSection = "start"
                }

                ValueBriefTile(
                    label: "4. Remember",
                    title: "Outcome Writeback",
                    detail: "Commit what changed, why it matters, evidence, and the next action to durable memory.",
                    action: "Copy Proof",
                    symbol: "square.and.arrow.down.fill",
                    accent: .green
                ) {
                    Task { await model.copyValueProof() }
                }
            }

            focusIdeaCapturePanel(focus)
            valueBriefPanel
            startHereOutcomePanel(project: focus.project)
        }
    }

    private var demoView: some View {
        VStack(alignment: .leading, spacing: 18) {
            valueSurfaceHero(
                eyebrow: "Demo",
                title: "See the loop with temporary data.",
                detail: "Seed realistic ideas and outcomes, then review what bubbles up before touching your real workspace.",
                symbol: "play.rectangle.fill",
                primaryTitle: "Copy Demo",
                primarySymbol: "play.rectangle.fill",
                primaryAction: { Task { await model.copyDemo() } },
                secondaryTitle: "Open Playbook",
                secondarySymbol: "book.closed.fill",
                secondaryAction: { selectedSection = "playbook" },
                output: model.demoCopyOutput
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                ValueBriefTile(label: "1. Seed", title: "Temporary workspace", detail: "Creates safe sample ideas, a delegated loop, and an accepted outcome.", action: "Copy Demo", symbol: "tray.and.arrow.down.fill", accent: settings.theme.accent) {
                    Task { await model.copyDemo() }
                }
                ValueBriefTile(label: "2. Surface", title: "Bubble Up", detail: "Shows what deserves attention before it becomes background noise.", action: "Work Block", symbol: "arrow.up.forward.circle.fill", accent: .blue) {
                    selectedSection = "work-block"
                }
                ValueBriefTile(label: "3. Apply", title: "Use real commands", detail: "The demo ends with the exact commands for your real workspace.", action: "Playbook", symbol: "book.closed.fill", accent: .green) {
                    selectedSection = "playbook"
                }
            }
        }
    }

    private var playbookView: some View {
        VStack(alignment: .leading, spacing: 18) {
            valueSurfaceHero(
                eyebrow: "Playbook",
                title: "Pick the right command fast.",
                detail: "A compact map for capture, Oracle reads, agent handoff, outcome writeback, and runtime checks.",
                symbol: "book.closed.fill",
                primaryTitle: "Copy Playbook",
                primarySymbol: "book.closed.fill",
                primaryAction: { Task { await model.copyPlaybook() } },
                secondaryTitle: "Run Work Block",
                secondarySymbol: "target",
                secondaryAction: { selectedSection = "work-block" },
                output: model.playbookCopyOutput
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                ValueBriefTile(label: "Capture", title: "Save a thought", detail: "Use idea capture when something should not disappear.", action: "Capture", symbol: "lightbulb.fill", accent: .yellow) {
                    model.quickIdea = "Capture this rough thought."
                    selectedSection = "focus"
                }
                ValueBriefTile(label: "Decide", title: "Ask Oracle", detail: "Use the direct read when you need the missing signal or cheapest test.", action: "Oracle", symbol: "sparkle.magnifyingglass", accent: settings.theme.accent) {
                    selectedSection = "oracle"
                }
                ValueBriefTile(label: "Close", title: "Commit Outcome", detail: "Use outcome writeback when work changes something worth remembering.", action: "Outcome", symbol: "square.and.arrow.down.fill", accent: .green) {
                    selectedSection = "start-here"
                }
            }
        }
    }

    private var valueAuditView: some View {
        VStack(alignment: .leading, spacing: 18) {
            valueSurfaceHero(
                eyebrow: "Value Audit",
                title: "Evidence, not vibes.",
                detail: "Checks whether the first-use value path is covered and names the remaining native UI gaps.",
                symbol: "checkmark.seal.fill",
                primaryTitle: "Copy Audit",
                primarySymbol: "checkmark.seal.fill",
                primaryAction: { Task { await model.copyValueAudit() } },
                secondaryTitle: "Open Demo",
                secondarySymbol: "play.rectangle.fill",
                secondaryAction: { selectedSection = "demo" },
                output: model.valueAuditCopyOutput
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                ValueBriefTile(label: "Covered", title: "CLI and MCP value", detail: "First Minute, Demo, Playbook, Work Block, capture, review, Bubble Up, and outcome writeback.", action: "Playbook", symbol: "checkmark.circle.fill", accent: .green) {
                    selectedSection = "playbook"
                }
                ValueBriefTile(label: "Gap", title: "Native UI certification", detail: "Visual polish still needs an explicit UI review because checks intentionally avoid opening the app.", action: "System", symbol: "exclamationmark.triangle.fill", accent: .orange) {
                    selectedSection = "system"
                }
                ValueBriefTile(label: "Next", title: "Run real loop", detail: "Use Work Block on the actual workspace and write one outcome back.", action: "Work Block", symbol: "target", accent: settings.theme.accent) {
                    selectedSection = "work-block"
                }
            }
        }
    }

    private func valueSurfaceHero(
        eyebrow: String,
        title: String,
        detail: String,
        symbol: String,
        primaryTitle: String,
        primarySymbol: String,
        primaryAction: @escaping () -> Void,
        secondaryTitle: String,
        secondarySymbol: String,
        secondaryAction: @escaping () -> Void,
        output: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(settings.theme.accent)
                    .frame(width: 58, height: 58)
                    .background(settings.theme.accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(eyebrow)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(settings.theme.accent)
                        .textCase(.uppercase)
                    Text(title)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                    Text(detail)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
                StatusPill(text: "Non-launching", state: .good)
            }

            HStack(spacing: 8) {
                Button(action: primaryAction) {
                    Label(primaryTitle, systemImage: primarySymbol)
                }
                .buttonStyle(.borderedProminent)

                Button(action: secondaryAction) {
                    Label(secondaryTitle, systemImage: secondarySymbol)
                }
                .buttonStyle(.bordered)

                Button { Task { await model.copyWorkBlock() } } label: {
                    Label("Work Block", systemImage: "target")
                }
                .buttonStyle(.bordered)
            }

            if !output.isEmpty || !model.workBlockCopyOutput.isEmpty {
                Text(output.isEmpty ? model.workBlockCopyOutput : output)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .padding(20)
        .darkPanel()
    }

    private var nowView: some View {
        let focus = model.focusItem
        let review = model.oracleCommits.first { $0.status == .new || $0.status == .delegated }
        let project = model.projects.first
        let processState = model.summaryLine == "Brain status ready" ? "Ready" : model.summaryLine

        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(settings.theme.accent)
                        .frame(width: 58, height: 58)
                        .background(settings.theme.accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Terminal Brain Now")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(settings.theme.accent)
                            .textCase(.uppercase)
                        Text("Do \(focus.title)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                        Text(focus.project)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(focus.state.color)
                    }
                    Spacer()
                    StatusPill(text: processState, state: model.summaryLine == "Brain status ready" ? .good : .warn)
                }

                Text(focus.reason)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.64))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Button { Task { await model.copyNow() } } label: {
                        Label("Copy Now", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        applyFocusAction(focus)
                    } label: {
                        Label(focus.action, systemImage: focus.symbol)
                    }
                    .buttonStyle(.bordered)

                    Button { Task { await model.copyAgentPrompt() } } label: {
                        Label("Agent Prompt", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        model.workQuery = focus.query.isEmpty ? focus.title : focus.query
                        selectedSection = "start"
                    } label: {
                        Label("Start Work", systemImage: "shippingbox.fill")
                    }
                    .buttonStyle(.bordered)

                    Button { Task { await model.copyStartHere() } } label: {
                        Label("Copy Start Here", systemImage: "play.circle.fill")
                    }
                    .buttonStyle(.bordered)
                }
                if !model.nowCopyOutput.isEmpty || !model.startHereCopyOutput.isEmpty || !model.agentPromptCopyOutput.isEmpty {
                    Text(!model.nowCopyOutput.isEmpty ? model.nowCopyOutput : (model.startHereCopyOutput.isEmpty ? model.agentPromptCopyOutput : model.startHereCopyOutput))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
            .padding(20)
            .darkPanel()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 12)], spacing: 12) {
                ValueBriefTile(
                    label: "Bottom line",
                    title: focus.title,
                    detail: "This is the current highest-signal work block. Treat it as the default unless a fresher constraint appears.",
                    action: focus.action,
                    symbol: focus.symbol,
                    accent: focus.state.color
                ) {
                    applyFocusAction(focus)
                }

                ValueBriefTile(
                    label: "Process truth",
                    title: processState,
                    detail: "The app surface shows readiness without background agents launching, quitting, or stealing focus.",
                    action: "Open Setup",
                    symbol: "checklist.checked",
                    accent: model.summaryLine == "Brain status ready" ? .green : .orange
                ) {
                    selectedSection = "setup"
                }

                ValueBriefTile(
                    label: "Memory to attach",
                    title: project?.name ?? "Build a context pack",
                    detail: project?.recommendedAction ?? "Attach source-grounded memory before handing deeper work to an agent.",
                    action: project == nil ? "Start Work" : "Open Project",
                    symbol: project?.symbol ?? "shippingbox.fill",
                    accent: project?.accent ?? settings.theme.accent
                ) {
                    if let project {
                        selectedProjectID = project.id
                        selectedSection = "projects"
                    } else {
                        model.workQuery = focus.query.isEmpty ? focus.title : focus.query
                        selectedSection = "start"
                    }
                }

                ValueBriefTile(
                    label: "Close loop",
                    title: review?.title ?? "Commit the outcome",
                    detail: review?.preview ?? "Write what changed, why it matters, evidence, and the next action into durable memory.",
                    action: review == nil ? "Commit Below" : "Open Review",
                    symbol: review?.status.symbol ?? "square.and.arrow.down.fill",
                    accent: review?.status.color ?? .green
                ) {
                    if let review {
                        selectedCommitID = review.id
                        reviewProjectFilter = review.project.isEmpty ? "all" : review.project
                        selectedSection = "review"
                    }
                }
            }

            valueBriefPanel
            oracleDigestPanel
            startHereOutcomePanel(project: focus.project)
        }
    }

    private var valueNowView: some View {
        VStack(alignment: .leading, spacing: 18) {
            valueBriefPanel
            oracleDigestPanel
            operatorBriefPanel

            HStack(spacing: 8) {
                Button { Task { await model.copyValueBrief() } } label: {
                    Label("Copy Value", systemImage: "bolt.fill")
                }
                .buttonStyle(.borderedProminent)

                Button { Task { await model.copyStartHere() } } label: {
                    Label("Copy Start Here", systemImage: "play.circle.fill")
                }
                .buttonStyle(.bordered)

                Button { Task { await model.copyAgentPrompt() } } label: {
                    Label("Agent Prompt", systemImage: "paperplane.fill")
                }
                .buttonStyle(.bordered)

                Button {
                    model.workQuery = model.focusItem.query.isEmpty ? model.focusItem.title : model.focusItem.query
                    selectedSection = "start"
                } label: {
                    Label("Start Work", systemImage: "shippingbox.fill")
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .darkPanel()

            startHereOutcomePanel(project: model.focusItem.project)
        }
    }

    private var startHereView: some View {
        let focus = model.focusItem
        let review = model.oracleCommits.first { $0.status == .new || $0.status == .delegated }
        let project = model.projects.first

        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(settings.theme.accent)
                        .frame(width: 58, height: 58)
                        .background(settings.theme.accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Start Here")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(settings.theme.accent)
                            .textCase(.uppercase)
                        Text("One block. One artifact. One written outcome.")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.74)
                        Text(focus.project)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(focus.state.color)
                    }
                    Spacer()
                }

                Text(focus.reason)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.64))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Button { Task { await model.copyStartHere() } } label: {
                        Label("Copy Start Here", systemImage: "play.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    Button { Task { await model.copyOracleDigest() } } label: {
                        Label("Copy Digest", systemImage: "sparkle.magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    Button { Task { await model.copyAgentPrompt() } } label: {
                        Label("Agent Prompt", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(.bordered)
                    Button {
                        model.workQuery = focus.query.isEmpty ? focus.title : focus.query
                        selectedSection = "start"
                    } label: {
                        Label("Start Work", systemImage: "shippingbox.fill")
                    }
                    .buttonStyle(.bordered)
                }
                if !model.startHereCopyOutput.isEmpty || !model.oracleDigestCopyOutput.isEmpty || !model.agentPromptCopyOutput.isEmpty {
                    Text(!model.startHereCopyOutput.isEmpty ? model.startHereCopyOutput : (model.oracleDigestCopyOutput.isEmpty ? model.agentPromptCopyOutput : model.oracleDigestCopyOutput))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
            .padding(20)
            .darkPanel()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 12)], spacing: 12) {
                ValueBriefTile(
                    label: "1. Read",
                    title: "Oracle Digest",
                    detail: "Notice, decide, test, create, and avoid before handing work to an agent.",
                    action: "Copy Digest",
                    symbol: "sparkle.magnifyingglass",
                    accent: settings.theme.accent
                ) {
                    Task { await model.copyOracleDigest() }
                }

                ValueBriefTile(
                    label: "2. Act",
                    title: focus.title,
                    detail: focus.detail,
                    action: focus.action,
                    symbol: focus.symbol,
                    accent: focus.state.color
                ) {
                    applyFocusAction(focus)
                }

                ValueBriefTile(
                    label: "3. Attach",
                    title: project?.name ?? "Build a context pack",
                    detail: project?.recommendedAction ?? "Create source-grounded working memory before deeper implementation.",
                    action: project == nil ? "Start Work" : "Open Project",
                    symbol: project?.symbol ?? "shippingbox.fill",
                    accent: project?.accent ?? settings.theme.accent
                ) {
                    if let project {
                        selectedProjectID = project.id
                        selectedSection = "projects"
                    } else {
                        model.workQuery = focus.query.isEmpty ? focus.title : focus.query
                        selectedSection = "start"
                    }
                }

                ValueBriefTile(
                    label: "4. Close",
                    title: review?.title ?? "Commit the outcome",
                    detail: review?.preview ?? "Write what changed, why it matters, and the next action into durable memory.",
                    action: review == nil ? "Commit Below" : "Review",
                    symbol: review?.status.symbol ?? "square.and.arrow.down.fill",
                    accent: review?.status.color ?? .green
                ) {
                    if let review {
                        selectedCommitID = review.id
                        reviewProjectFilter = review.project.isEmpty ? "all" : review.project
                        selectedSection = "review"
                    }
                }
            }

            startHereOutcomePanel(project: focus.project)
        }
    }

    private func startHereOutcomePanel(project: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("Commit Outcome", symbol: "square.and.arrow.down.fill")
                Spacer()
                Text("Close the loop")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))
                    .textCase(.uppercase)
            }

            TextField("Outcome title", text: $model.outcomeTitle)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $model.outcomeText)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.82))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 92)
                .padding(8)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))

            TextField("Next action", text: $model.outcomeNextAction)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                Button {
                    Task { await model.commitOutcome(project: project) }
                } label: {
                    Label("Commit Outcome", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.outcomeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    model.outcomeTitle = "Outcome - \(model.focusItem.title)"
                    model.outcomeText = "Changed:\n\nWhy it matters:\n\nEvidence:"
                    model.outcomeNextAction = model.focusItem.action
                } label: {
                    Label("Template", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.bordered)
            }

            if !model.outcomeOutput.isEmpty {
                Text(model.outcomeOutput)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
        }
        .padding(16)
        .darkPanel()
    }

    private var focusView: some View {
        let item = model.focusItem
        return VStack(alignment: .leading, spacing: 18) {
            valueBriefPanel
            oracleDigestPanel
            operatorBriefPanel
            operatorDeck

            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(item.state.color)
                            .frame(width: 58, height: 58)
                            .background(item.state.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Do this now")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(settings.theme.accent)
                                .textCase(.uppercase)
                            Text(item.title)
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.72)
                            Text(item.project)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(item.state.color)
                        }
                        Spacer()
                        Text("\(item.score)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(item.state.color.opacity(0.18), in: Capsule())
                    }

                    Text(item.detail)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(item.reason)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.64))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Button {
                            applyFocusAction(item)
                        } label: {
                            Label(item.action, systemImage: "arrow.right.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        Button {
                            model.oracleQuestion = "What should I do about \(item.title)? \(item.reason)"
                            selectedSection = "oracle"
                        } label: {
                            Label("Ask Oracle", systemImage: "sparkle.magnifyingglass")
                        }
                        .buttonStyle(.bordered)
                        Button {
                            selectedSection = "radar"
                        } label: {
                            Label("Show Radar", systemImage: "scope")
                        }
                        .buttonStyle(.bordered)
                        Button {
                            Task { await model.copyOperatorSnapshot() }
                        } label: {
                            Label("Snapshot", systemImage: "doc.on.clipboard")
                        }
                        .buttonStyle(.bordered)
                        if let path = item.path {
                            Button { model.openPath(path) } label: {
                                Label("Open", systemImage: "arrow.up.right.square")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    if !model.snapshotCopyOutput.isEmpty {
                        Text(model.snapshotCopyOutput)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                    }
                }
                .padding(20)
                .darkPanel()

                VStack(alignment: .leading, spacing: 14) {
                    SectionTitle("Why This Won", symbol: "list.bullet.clipboard")
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(model.radarItems.prefix(4)) { radar in
                            HStack(spacing: 10) {
                                Text("\(radar.score)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 34)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(radar.title)
                                        .font(.callout.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.82))
                                        .lineLimit(1)
                                    Text(radar.evidence.joined(separator: " • "))
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.46))
                                        .lineLimit(2)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(12)
                    .darkPanel()

                    focusOraclePanel(item)
                    focusIdeaCapturePanel(item)
                    focusTrailPanel
                }
                .frame(width: 420)
            }
        }
    }

    private var valueBriefPanel: some View {
        let focus = model.focusItem
        let idea = model.ideaPulseItems.first
        let blindspot = model.blindspotItems.first
        let project = model.projects.first

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("Value Brief", symbol: "bolt.fill")
                Spacer()
                if !model.agentPromptCopyOutput.isEmpty || !model.valueBriefCopyOutput.isEmpty {
                    Text(model.agentPromptCopyOutput.isEmpty ? model.valueBriefCopyOutput : model.agentPromptCopyOutput)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.48))
                        .lineLimit(1)
                }
                Button {
                    Task { await model.copyAgentPrompt() }
                } label: {
                    Label("Agent Prompt", systemImage: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                Button {
                    Task { await model.copyValueBrief() }
                } label: {
                    Label("Copy", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Text("Why this is worth it")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))
                    .textCase(.uppercase)
            }

            Text("Do \(focus.title)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.76)

            Text("The highest-value move is \(focus.action.lowercased()) for \(focus.project). It has an execution signal, an upside test, a risk check, and a next artifact path.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.64))
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 12)], spacing: 12) {
                ValueBriefTile(
                    label: "Immediate value",
                    title: focus.title,
                    detail: focus.reason,
                    action: focus.action,
                    symbol: focus.symbol,
                    accent: focus.state.color
                ) {
                    applyFocusAction(focus)
                }

                ValueBriefTile(
                    label: "Upside to test",
                    title: idea?.title ?? "No idea test visible",
                    detail: idea?.nextPrompt ?? "Capture or sync more material to surface an idea worth testing.",
                    action: "Pressure Test",
                    symbol: idea?.symbol ?? "lightbulb.fill",
                    accent: idea?.state.color ?? .cyan
                ) {
                    if let idea {
                        selectedIdeaID = idea.id
                        selectedSection = "ideas"
                    } else {
                        selectedSection = "ideas"
                    }
                }

                ValueBriefTile(
                    label: "Risk to reduce",
                    title: blindspot?.title ?? "No strong blindspot visible",
                    detail: blindspot?.question ?? "Ask what is not represented in durable memory.",
                    action: blindspot?.nextAction ?? "Ask Oracle",
                    symbol: blindspot?.symbol ?? "eye.fill",
                    accent: blindspot?.state.color ?? .orange
                ) {
                    if let blindspot {
                        selectedBlindspotID = blindspot.id
                    }
                    selectedSection = "blindspots"
                }

                ValueBriefTile(
                    label: "Artifact to create",
                    title: project?.name ?? model.dailyCommands.first?.title ?? "Build a context pack",
                    detail: project?.recommendedAction ?? model.dailyCommands.first?.detail ?? "Create one durable artifact from the current focus.",
                    action: "Start Work",
                    symbol: project?.symbol ?? "shippingbox.fill",
                    accent: project?.accent ?? settings.theme.accent
                ) {
                    if let project {
                        selectedProjectID = project.id
                        selectedSection = "projects"
                    } else {
                        model.workQuery = focus.query.isEmpty ? focus.title : focus.query
                        selectedSection = "start"
                    }
                }
            }
        }
        .padding(16)
        .darkPanel()
    }

    private var oracleDigestPanel: some View {
        let focus = model.focusItem
        let review = model.oracleCommits.first { $0.status == .new || $0.status == .delegated }
        let idea = model.ideaPulseItems.first
        let blindspot = model.blindspotItems.first
        let project = model.projects.first

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("Oracle Digest", symbol: "sparkle.magnifyingglass")
                Spacer()
                if !model.oracleBriefCopyOutput.isEmpty || !model.oracleDigestCopyOutput.isEmpty {
                    Text(model.oracleBriefCopyOutput.isEmpty ? model.oracleDigestCopyOutput : model.oracleBriefCopyOutput)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.48))
                        .lineLimit(1)
                }
                Button {
                    Task { await model.copyOracleBrief() }
                } label: {
                    Label("Copy Brief", systemImage: "wand.and.stars")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                Button {
                    Task { await model.copyOracleDigest() }
                } label: {
                    Label("Copy Digest", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Text("Notice, decide, test, create, avoid")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))
                    .textCase(.uppercase)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 12)], spacing: 12) {
                ValueBriefTile(
                    label: "Notice",
                    title: focus.title,
                    detail: focus.reason,
                    action: focus.action,
                    symbol: focus.symbol,
                    accent: focus.state.color
                ) {
                    applyFocusAction(focus)
                }

                ValueBriefTile(
                    label: "Decide",
                    title: review?.title ?? blindspot?.title ?? "No unresolved decision visible",
                    detail: review?.preview ?? blindspot?.question ?? "Ask what should be accepted, linked, delegated, or dismissed.",
                    action: review == nil ? "Ask Oracle" : "Open Review",
                    symbol: review?.status.symbol ?? blindspot?.symbol ?? "tray.and.arrow.down.fill",
                    accent: review?.status.color ?? blindspot?.state.color ?? .orange
                ) {
                    if let review {
                        selectedCommitID = review.id
                        reviewProjectFilter = review.project.isEmpty ? "all" : review.project
                        selectedSection = "review"
                    } else if let blindspot {
                        selectedBlindspotID = blindspot.id
                        selectedSection = "blindspots"
                    } else {
                        model.oracleQuestion = "What decision am I avoiding right now?"
                        selectedSection = "oracle"
                    }
                }

                ValueBriefTile(
                    label: "Test",
                    title: idea?.title ?? "No idea test visible",
                    detail: idea?.nextPrompt ?? "Capture one rough thought or sync more material to surface a cheap test.",
                    action: "Pressure Test",
                    symbol: idea?.symbol ?? "lightbulb.fill",
                    accent: idea?.state.color ?? .cyan
                ) {
                    if let idea {
                        selectedIdeaID = idea.id
                    }
                    selectedSection = "ideas"
                }

                ValueBriefTile(
                    label: "Create",
                    title: project?.name ?? model.dailyCommands.first?.title ?? focus.title,
                    detail: project?.recommendedAction ?? model.dailyCommands.first?.detail ?? "Create one durable artifact from the current focus.",
                    action: "Start Work",
                    symbol: project?.symbol ?? "shippingbox.fill",
                    accent: project?.accent ?? settings.theme.accent
                ) {
                    if let project {
                        selectedProjectID = project.id
                        selectedSection = "projects"
                    } else {
                        model.workQuery = focus.query.isEmpty ? focus.title : focus.query
                        selectedSection = "start"
                    }
                }

                ValueBriefTile(
                    label: "Avoid",
                    title: blindspot?.title ?? "Signal collection without closure",
                    detail: blindspot?.why ?? "Do not let asks, reviews, and ideas pile up without a committed outcome.",
                    action: blindspot?.nextAction ?? "Commit Outcome",
                    symbol: blindspot?.symbol ?? "eye.fill",
                    accent: blindspot?.state.color ?? .red
                ) {
                    if let blindspot {
                        selectedBlindspotID = blindspot.id
                        selectedSection = "blindspots"
                    } else {
                        model.quickIdea = "Outcome: "
                    }
                }
            }
        }
        .padding(16)
        .darkPanel()
    }

    private var operatorBriefPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("Operator Brief", symbol: "wand.and.stars")
                Spacer()
                if !model.valueBriefCopyOutput.isEmpty || !model.briefCopyOutput.isEmpty || !model.decisionLaneCopyOutput.isEmpty {
                    Text(!model.valueBriefCopyOutput.isEmpty ? model.valueBriefCopyOutput : (model.briefCopyOutput.isEmpty ? model.decisionLaneCopyOutput : model.briefCopyOutput))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.48))
                        .lineLimit(1)
                }
                Button {
                    Task { await model.copyValueBrief() }
                } label: {
                    Label("Value", systemImage: "bolt.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                Button {
                    Task { await model.copyOperatorBrief() }
                } label: {
                    Label("Copy Brief", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Button {
                    Task { await model.copyDecisionLane() }
                } label: {
                    Label("Decision Lane", systemImage: "list.number")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Text("Plain-English value read")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))
                    .textCase(.uppercase)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                ForEach(model.operatorBrief) { item in
                    Button {
                        applyOperatorBrief(item)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: item.symbol)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(item.state.color)
                                    .frame(width: 34, height: 34)
                                    .background(item.state.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.label)
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(item.state.color)
                                        .textCase(.uppercase)
                                    Text(item.title)
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.82)
                                }
                                Spacer()
                            }

                            Text(item.detail)
                                .font(.callout)
                                .foregroundStyle(.white.opacity(0.62))
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 8) {
                                Text(item.project.isEmpty ? "General Brain" : item.project)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.46))
                                    .lineLimit(1)
                                Spacer()
                                Label(item.action, systemImage: "arrow.right.circle.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(item.state.color)
                                    .lineLimit(1)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 164, alignment: .topLeading)
                        .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .darkPanel()
    }

    private var operatorDeck: some View {
        let focus = model.focusItem
        let bubble = model.oracleItems.first
        let review = model.oracleCommits.first { $0.status == .new || $0.status == .delegated }
        let radar = model.radarItems.first { $0.disposition == .fresh } ?? model.radarItems.first
        let project = model.projects.first

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle("Operator Deck", symbol: "rectangle.stack.fill")
                Spacer()
                if !model.handoffCopyOutput.isEmpty || !model.deckCopyOutput.isEmpty {
                    Text(model.handoffCopyOutput.isEmpty ? model.deckCopyOutput : model.handoffCopyOutput)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.48))
                        .lineLimit(1)
                }
                Button {
                    Task { await model.copyOperatorDeck() }
                } label: {
                    Label("Copy", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Copy Operator Deck Markdown")
                Button {
                    Task { await model.copyHandoff() }
                } label: {
                    Label("Handoff", systemImage: "doc.richtext")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .help("Copy full agent handoff")
                Text("Read left to right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))
                    .textCase(.uppercase)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                OperatorDeckCard(
                    kicker: "Do First",
                    title: focus.title,
                    detail: focus.reason,
                        symbol: focus.symbol,
                        accent: focus.state.color,
                        primaryTitle: focus.action,
                        primarySymbol: "arrow.right.circle.fill",
                        secondaryTitle: "Ask",
                        secondarySymbol: "sparkle.magnifyingglass",
                        secondaryAction: {
                            model.oracleQuestion = "What should I do about \(focus.title)? \(focus.reason)"
                            selectedSection = "oracle"
                        }
                    ) {
                        applyFocusAction(focus)
                    }

                if let bubble {
                    OperatorDeckCard(
                        kicker: bubble.kind.label,
                        title: bubble.title,
                        detail: bubble.detail,
                        symbol: bubble.symbol,
                        accent: settings.theme.accent,
                        primaryTitle: "Ask",
                        primarySymbol: "sparkle.magnifyingglass",
                        secondaryTitle: "Promote",
                        secondarySymbol: "pin.fill",
                        secondaryAction: {
                            model.promoteOracleItem(bubble)
                        }
                    ) {
                        model.oracleQuestion = "What should I notice about \(bubble.title)? \(bubble.detail)"
                        selectedSection = "oracle"
                        Task { await model.askOracle() }
                    }
                } else if let radar {
                    OperatorDeckCard(
                        kicker: "Radar",
                        title: radar.title,
                        detail: radar.reason,
                        symbol: radar.symbol,
                        accent: radar.state.color,
                        primaryTitle: radar.action,
                        primarySymbol: "scope",
                        secondaryTitle: "Watch",
                        secondarySymbol: "eye",
                        secondaryAction: {
                            model.setRadarDisposition(radar, disposition: .watching)
                        }
                    ) {
                        selectedRadarID = radar.id
                        applyRadarAction(radar)
                    }
                }

                if let review {
                    OperatorDeckCard(
                        kicker: review.status.label,
                        title: review.title,
                        detail: review.preview,
                        symbol: review.status.symbol,
                        accent: review.status.color,
                        primaryTitle: "Review",
                        primarySymbol: "tray.and.arrow.down.fill",
                        secondaryTitle: review.status == .new ? "Accept" : "Delegate",
                        secondarySymbol: review.status == .new ? "checkmark.seal.fill" : "paperplane.fill",
                        secondaryAction: {
                            if review.status == .new {
                                model.setOracleCommitStatus(review, status: .accepted)
                            } else {
                                model.delegateOracleCommitToStartWork(review)
                                selectedSection = "start"
                            }
                        }
                    ) {
                        selectedCommitID = review.id
                        reviewProjectFilter = review.project.isEmpty ? "all" : review.project
                        selectedSection = "review"
                    }
                } else {
                    OperatorDeckCard(
                        kicker: "Capture",
                        title: "Save the thought before it disappears",
                        detail: "Drop a raw idea into the focus capture box and Terminal Brain will turn it into reviewable memory.",
                        symbol: "lightbulb.fill",
                        accent: .cyan,
                        primaryTitle: "Capture",
                        primarySymbol: "square.and.pencil"
                    ) {
                        model.quickIdea = "Idea: "
                        selectedSection = "focus"
                    }
                }

                if let project {
                    OperatorDeckCard(
                        kicker: "Project",
                        title: project.name,
                        detail: project.recommendedAction,
                        symbol: project.symbol,
                        accent: project.accent,
                        primaryTitle: "Open",
                        primarySymbol: "folder.fill",
                        secondaryTitle: "Pack",
                        secondarySymbol: "shippingbox.fill",
                        secondaryAction: {
                            Task {
                                await model.buildPack(for: project)
                                selectedSection = "start"
                            }
                        }
                    ) {
                        selectedProjectID = project.id
                        selectedSection = "projects"
                    }
                } else {
                    OperatorDeckCard(
                        kicker: "Start Work",
                        title: "Build the first context pack",
                        detail: "Use a short query to create an agent handoff from local memory and Mission Control.",
                        symbol: "shippingbox.fill",
                        accent: settings.theme.accent,
                        primaryTitle: "Start",
                        primarySymbol: "sparkles"
                    ) {
                        selectedSection = "start"
                    }
                }
            }
        }
    }

    private func focusOraclePanel(_ item: FocusItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Ask About This", symbol: "sparkle.magnifyingglass")
            VStack(alignment: .leading, spacing: 12) {
                TextField("Ask a follow-up about the current focus", text: $model.oracleQuestion)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { askFocusOracle(item) }

                HStack(spacing: 8) {
                    Button { askFocusOracle(item) } label: {
                        Label(model.isAskingOracle ? "Asking" : "Ask", systemImage: "return")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isAskingOracle)

                    Button { askFocusOracle(item, intent: "What am I missing?") } label: {
                        Label("Missing", systemImage: "eye")
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isAskingOracle)

                    Button { askFocusOracle(item, intent: "What is the next concrete action?") } label: {
                        Label("Next", systemImage: "arrow.right")
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isAskingOracle)
                }

                HStack(spacing: 8) {
                    Button { askFocusOracle(item, intent: "Turn this into a short execution plan.") } label: {
                        Label("Plan", systemImage: "checklist")
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isAskingOracle)

                    Button {
                        Task {
                            await model.commitOracleAnswer(project: item.project)
                            selectedSection = "review"
                        }
                    } label: {
                        Label("Commit", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.oracleAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isAskingOracle)
                }

                if model.isAskingOracle {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Grounding answer in the current focus signal")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                    }
                }

                if !model.oracleAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(model.oracleMode.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(settings.theme.accent)
                    Text(model.oracleAnswer)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(10)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)

                    if !model.oracleSuggestedActions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(model.oracleSuggestedActions.prefix(4), id: \.self) { action in
                                Button {
                                    applyOracleSuggestion(action)
                                } label: {
                                    Label(action, systemImage: symbolForOracleSuggestion(action))
                                        .lineLimit(1)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            .padding(12)
            .darkPanel()
        }
    }

    private func focusIdeaCapturePanel(_ item: FocusItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Capture Thought", symbol: "lightbulb")
            VStack(alignment: .leading, spacing: 10) {
                TextEditor(text: $model.quickIdea)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.82))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 78)
                    .padding(8)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))

                HStack(spacing: 8) {
                    Button {
                        Task { await model.captureIdea(project: item.project) }
                    } label: {
                        Label("Capture", systemImage: "tray.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.quickIdea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        model.quickIdea = "Idea from \(item.project): \(item.title)\n\(item.reason)"
                    } label: {
                        Label("Use Focus", systemImage: "target")
                    }
                    .buttonStyle(.bordered)
                }

                if !model.quickIdeaOutput.isEmpty {
                    Text(model.quickIdeaOutput)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(2)
                }
            }
            .padding(12)
            .darkPanel()
        }
    }

    private var focusTrailPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle("Memory Trail", symbol: "clock.arrow.circlepath")
                Spacer()
                Button {
                    selectedSection = "review"
                } label: {
                    Image(systemName: "arrow.right")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Open Review")
            }

            VStack(spacing: 0) {
                ForEach(model.oracleCommits.prefix(4)) { commit in
                    Button {
                        selectedCommitID = commit.id
                        selectedSection = "review"
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: commit.status.symbol)
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(commit.status.color)
                                .frame(width: 24, height: 24)
                                .background(commit.status.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(commit.title)
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.84))
                                    .lineLimit(1)
                                Text("\(commit.project) - \(commit.status.label)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.48))
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)

                    if commit.id != model.oracleCommits.prefix(4).last?.id {
                        Divider().overlay(.white.opacity(0.08)).padding(.leading, 34)
                    }
                }

                if model.oracleCommits.isEmpty {
                    EmptyStateRow(
                        title: "No memory trail yet",
                        detail: "Ask, commit, or capture a thought and it will appear here.",
                        symbol: "tray"
                    )
                }
            }
            .padding(12)
            .darkPanel()
        }
    }

    private var setupView: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Readiness Checklist", symbol: "checklist.checked")
                VStack(spacing: 0) {
                    ForEach(model.setupSteps) { step in
                        SetupStepRow(step: step)
                        if step.id != model.setupSteps.last?.id {
                            Divider().overlay(.white.opacity(0.08)).padding(.leading, 50)
                        }
                    }
                    if model.setupSteps.isEmpty {
                        EmptyStateRow(title: "Setup has not run yet", detail: "Refresh status to build the readiness checklist.", symbol: "checklist")
                    }
                }
                .darkPanel()
            }
            .frame(minWidth: 560)

            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Bring Online", symbol: "switch.2")
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        SourceInfoPill(title: "Ready", value: "\(model.setupSteps.filter { $0.state == .good }.count)", symbol: "checkmark.seal")
                        SourceInfoPill(title: "Attention", value: "\(model.setupAttentionCount)", symbol: "exclamationmark.triangle")
                    }
                    Text(setupSummary)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button { Task { await model.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                        Button { Task { await model.runSyncNow() } } label: { Label("Run Sync", systemImage: "arrow.triangle.2.circlepath") }
                            .disabled(model.isSyncing)
                        Button { model.openWorkspace() } label: { Label("Workspace", systemImage: "folder") }
                        Button { model.openMissionControl() } label: { Label("Mission", systemImage: "display") }
                    }
                    .buttonStyle(.bordered)
                    HStack {
                        Button {
                            model.oracleQuestion = "What is missing from my Terminal Brain setup?"
                            selectedSection = "oracle"
                        } label: {
                            Label("Ask Oracle", systemImage: "sparkle.magnifyingglass")
                        }
                        .buttonStyle(.borderedProminent)
                        Button {
                            selectedSection = "start"
                        } label: {
                            Label("Start Work", systemImage: "shippingbox")
                        }
                        .buttonStyle(.bordered)
                        SettingsLink {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(16)
                .darkPanel()

                SectionTitle("Agent Contract", symbol: "antenna.radiowaves.left.and.right")
                VStack(alignment: .leading, spacing: 10) {
                    PolicyLine("Agents should read Terminal Brain readiness before starting work.")
                    PolicyLine("Agents should use the app MCP gateway instead of starting separate source bridges.")
                    PolicyLine("Apple Notes and Drafts stay explicit unless you opt in from the app.")
                    PolicyLine("Useful reads should be committed back into the Oracle Inbox.")
                }
                .padding(14)
                .darkPanel()
                syncOutput
            }
            .frame(width: 480)
        }
    }

    private var setupSummary: String {
        let attention = model.setupSteps.filter { $0.state == .warn }
        if attention.isEmpty {
            return "Terminal Brain is ready for agent work. The local app, MCP gateway, source policy, workspace, and memory writeback path are connected."
        }
        let names = attention.prefix(3).map(\.title).joined(separator: ", ")
        return "Resolve \(names) first. The checklist is generated from the current app state, local files, MCP config, and source policy."
    }

    private var radarView: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Signal Radar", symbol: "scope")
                VStack(spacing: 0) {
                    ForEach(model.radarItems) { item in
                        Button {
                            selectedRadarID = item.id
                        } label: {
                            RadarItemRow(item: item, selected: selectedRadarItem?.id == item.id)
                        }
                        .buttonStyle(.plain)
                        if item.id != model.radarItems.last?.id {
                            Divider().overlay(.white.opacity(0.08)).padding(.leading, 52)
                        }
                    }
                    if model.radarItems.isEmpty {
                        EmptyStateRow(title: "No radar signals", detail: "Refresh, sync, or ask Oracle to generate a useful signal.", symbol: "scope")
                    }
                }
                .darkPanel()
            }
            .frame(width: 500)

            VStack(alignment: .leading, spacing: 14) {
                if let item = selectedRadarItem {
                    SectionTitle("Why This Matters", symbol: item.symbol)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: item.symbol)
                                .font(.title2)
                                .foregroundStyle(item.state.color)
                                .frame(width: 42, height: 42)
                                .background(item.state.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.white)
                                Text("\(item.project) - \(item.urgency)")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(item.state.color)
                            }
                            Spacer()
                            Text("\(item.score)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(item.state.color.opacity(0.18), in: Capsule())
                            StatusPill(text: item.urgency, state: item.state)
                            Text(item.disposition.label)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.58))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.08), in: Capsule())
                        }

                        Text(item.detail)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.84))
                            .fixedSize(horizontal: false, vertical: true)

                        Text(item.reason)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.66))
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)

                        HStack(alignment: .center, spacing: 10) {
                            Label("Counter-signal", systemImage: "eye.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.70))
                            Text("Check blindspots before acting so the top radar signal does not become tunnel vision.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.56))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            Button {
                                selectedSection = "blindspots"
                            } label: {
                                Label("Check Blindspots", systemImage: "arrow.right.circle.fill")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(10)
                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.08), lineWidth: 1))

                        HStack(spacing: 8) {
                            ForEach(item.evidence, id: \.self) { evidence in
                                Text(evidence)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.60))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.07), in: Capsule())
                            }
                        }

                        if let path = item.path {
                            Text(path)
                                .font(.caption.monospaced())
                                .foregroundStyle(.white.opacity(0.44))
                                .lineLimit(2)
                                .textSelection(.enabled)
                        }

                        HStack {
                            Button {
                                applyRadarAction(item)
                            } label: {
                                Label(item.action, systemImage: "arrow.right.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            Button {
                                model.oracleQuestion = "What should I do about \(item.title)? \(item.reason)"
                                selectedSection = "oracle"
                            } label: {
                                Label("Ask Oracle", systemImage: "sparkle.magnifyingglass")
                            }
                            .buttonStyle(.bordered)
                            Button {
                                Task {
                                    await model.commitRadarItem(item)
                                    model.setRadarDisposition(item, disposition: .acted)
                                }
                            } label: {
                                Label("Commit Signal", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.bordered)
                            Button { model.setRadarDisposition(item, disposition: .watching) } label: {
                                Label("Watch", systemImage: "eye")
                            }
                            .buttonStyle(.bordered)
                            Button { model.setRadarDisposition(item, disposition: .acted) } label: {
                                Label("Acted", systemImage: "checkmark.seal")
                            }
                            .buttonStyle(.bordered)
                            Button { model.setRadarDisposition(item, disposition: .snoozed) } label: {
                                Label("Snooze", systemImage: "clock")
                            }
                            .buttonStyle(.bordered)
                            Button { model.setRadarDisposition(item, disposition: .dismissed) } label: {
                                Label("Dismiss", systemImage: "xmark.circle")
                            }
                            .buttonStyle(.bordered)
                            if let path = item.path {
                                Button { model.openPath(path) } label: {
                                    Label("Open", systemImage: "arrow.up.right.square")
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        if !model.oracleCommitOutput.isEmpty {
                            Text(model.oracleCommitOutput)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.52))
                                .lineLimit(2)
                        }
                    }
                    .padding(16)
                    .darkPanel()
                }

                SectionTitle("Radar Rules", symbol: "slider.horizontal.3")
                VStack(alignment: .leading, spacing: 10) {
                    PolicyLine("Delegated reads outrank passive ideas.")
                    PolicyLine("Unclassified Oracle commits stay visible until triaged.")
                    PolicyLine("Projects with open loops or stale activity resurface automatically.")
                    PolicyLine("Watched signals stay visible; acted, dismissed, and snoozed signals stop crowding the queue.")
                }
                .padding(14)
                .darkPanel()
            }
            .frame(minWidth: 620)
        }
    }

    private var blindspotsView: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionTitle("Blindspot Brief", symbol: "eye.fill")
                    Spacer()
                    if !model.blindspotCopyOutput.isEmpty {
                        Text(model.blindspotCopyOutput)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.48))
                            .lineLimit(1)
                    }
                    Button {
                        Task { await model.copyBlindspotBrief() }
                    } label: {
                        Label("Copy", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                VStack(spacing: 0) {
                    ForEach(model.blindspotItems) { item in
                        Button {
                            selectedBlindspotID = item.id
                        } label: {
                            BlindspotItemRow(item: item, selected: selectedBlindspotItem?.id == item.id)
                        }
                        .buttonStyle(.plain)
                        if item.id != model.blindspotItems.last?.id {
                            Divider().overlay(.white.opacity(0.08)).padding(.leading, 52)
                        }
                    }
                    if model.blindspotItems.isEmpty {
                        EmptyStateRow(title: "No blindspots surfaced", detail: "Refresh, sync, or capture an idea to give the brief more signal.", symbol: "eye")
                    }
                }
                .darkPanel()
            }
            .frame(width: 520)

            VStack(alignment: .leading, spacing: 14) {
                if let item = selectedBlindspotItem {
                    SectionTitle("Question To Ask", symbol: item.symbol)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: item.symbol)
                                .font(.title2)
                                .foregroundStyle(item.state.color)
                                .frame(width: 42, height: 42)
                                .background(item.state.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.white)
                                Text("\(item.project) - \(item.source)")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(item.state.color)
                            }
                            Spacer()
                            Text("\(item.score)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(item.state.color.opacity(0.18), in: Capsule())
                        }

                        Text(item.question)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.86))
                            .fixedSize(horizontal: false, vertical: true)

                        Text(item.why)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.66))
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)

                        if let path = item.path {
                            Text(path)
                                .font(.caption.monospaced())
                                .foregroundStyle(.white.opacity(0.44))
                                .lineLimit(2)
                                .textSelection(.enabled)
                        }

                        HStack {
                            Button {
                                applyBlindspotAction(item)
                            } label: {
                                Label(item.nextAction, systemImage: "arrow.right.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            Button {
                                Task { await model.askBlindspot(item) }
                            } label: {
                                Label(model.isAskingBlindspot ? "Asking" : "Ask Oracle", systemImage: "sparkle.magnifyingglass")
                            }
                            .buttonStyle(.bordered)
                            .disabled(model.isAskingBlindspot)
                            Button {
                                Task { await model.askBlindspot(item, commit: true) }
                            } label: {
                                Label("Ask + Commit", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.bordered)
                            .disabled(model.isAskingBlindspot)
                            Button {
                                model.quickIdea = "Blindspot: \(item.title)\n\nQuestion: \(item.question)\n\nWhy it matters: \(item.why)"
                                selectedSection = "ideas"
                            } label: {
                                Label("Capture as Idea", systemImage: "lightbulb.fill")
                            }
                            .buttonStyle(.bordered)
                            if item.source == "Oracle commit" || item.source == "Radar" {
                                Button {
                                    Task { await model.resolveBlindspot(item) }
                                } label: {
                                    Label("Resolve Source", systemImage: "checkmark.seal")
                                }
                                .buttonStyle(.bordered)
                                .disabled(model.isAskingBlindspot)
                            }
                            if item.source == "Oracle commit" {
                                Button {
                                    selectedCommitID = item.sourceID
                                    selectedSection = "review"
                                } label: {
                                    Label("Review", systemImage: "tray.and.arrow.down.fill")
                                }
                                .buttonStyle(.bordered)
                            }
                            if let path = item.path {
                                Button { model.openPath(path) } label: {
                                    Label("Open", systemImage: "arrow.up.right.square")
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        if !model.blindspotAnswer.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label(model.blindspotAnswerTitle.isEmpty ? "Oracle Answer" : model.blindspotAnswerTitle, systemImage: "text.bubble.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(item.state.color)
                                    Spacer()
                                    if !model.blindspotOutput.isEmpty {
                                        Text(model.blindspotOutput)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.white.opacity(0.46))
                                            .lineLimit(1)
                                    }
                                }
                                Text(model.blindspotAnswer)
                                    .font(.callout)
                                    .foregroundStyle(.white.opacity(0.72))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                            }
                            .padding(12)
                            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.09), lineWidth: 1))
                        } else if !model.blindspotOutput.isEmpty {
                            Text(model.blindspotOutput)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.52))
                                .lineLimit(2)
                        }
                    }
                    .padding(16)
                    .darkPanel()
                }

                SectionTitle("Blindspot Rules", symbol: "slider.horizontal.3")
                VStack(alignment: .leading, spacing: 10) {
                    PolicyLine("Delegated reads without artifacts outrank passive ideas.")
                    PolicyLine("New Oracle commits are treated as unresolved decisions.")
                    PolicyLine("Open loops and under-tested ideas appear before general project browsing.")
                    PolicyLine("Use this lane before broad planning so ignored work has a chance to object.")
                }
                .padding(14)
                .darkPanel()
            }
            .frame(minWidth: 620)
        }
    }

    private var heroPanel: some View {
        let mission = healthCard(named: "Mission Control")
        let sync = healthCard(named: "Edge Sync State")
        let memory = healthCard(named: "Obsidian Index")
        let attention = model.cards.filter { $0.state == .warn }.count
        return HStack(alignment: .bottom, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Brain gateway")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(settings.theme.accent)
                    .textCase(.uppercase)
                Text(attention == 0 && !model.cards.isEmpty ? "Ready for agent work." : "\(attention) item\(attention == 1 ? "" : "s") need attention.")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(heroDetail(mission: mission, sync: sync, memory: memory))
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.64))
                    .frame(maxWidth: 740, alignment: .leading)
            }
            Spacer()
            MetricTile(title: "Mission", value: mission?.value ?? "unknown", detail: mission?.state.rawValue ?? "not checked", symbol: mission?.symbol ?? "display")
            MetricTile(title: "Sync", value: sync?.value ?? "unknown", detail: sync?.state.rawValue ?? "not checked", symbol: sync?.symbol ?? "arrow.triangle.2.circlepath")
            MetricTile(title: "Memory", value: memory?.value ?? "unknown", detail: memory?.state.rawValue ?? "not checked", symbol: memory?.symbol ?? "brain")
        }
        .padding(20)
        .background(
            LinearGradient(colors: [.white.opacity(0.12), settings.theme.accent.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
    }

    private func healthCard(named title: String) -> HealthCard? {
        model.cards.first { $0.title == title }
    }

    private func heroDetail(mission: HealthCard?, sync: HealthCard?, memory: HealthCard?) -> String {
        let missionText = mission?.state == .good ? "Mission Control is reachable" : "Mission Control needs attention"
        let syncText = sync?.state == .good ? "sync state is populated" : "sync state needs attention"
        let memoryText = memory?.state == .good ? "durable memory is indexed" : "durable memory needs a refresh"
        return "Terminal Brain owns the local control plane: \(missionText), \(syncText), and \(memoryText). Sensitive sources remain explicit so agents can work through the MCP gateway without waking prompt-prone bridges."
    }

    private var ideasView: some View {
        let focus = model.focusItem

        return HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionTitle("Idea Pulse", symbol: "lightbulb.fill")
                    Spacer()
                    if !model.ideaPulseCopyOutput.isEmpty {
                        Text(model.ideaPulseCopyOutput)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.48))
                            .lineLimit(1)
                    }
                    Button {
                        Task { await model.copyIdeaPulse() }
                    } label: {
                        Label("Copy", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                VStack(spacing: 0) {
                    ForEach(model.ideaPulseItems) { item in
                        Button {
                            selectedIdeaID = item.id
                        } label: {
                            IdeaPulseRow(item: item, selected: selectedIdeaItem?.id == item.id)
                        }
                        .buttonStyle(.plain)
                        if item.id != model.ideaPulseItems.last?.id {
                            Divider().overlay(.white.opacity(0.08)).padding(.leading, 52)
                        }
                    }
                    if model.ideaPulseItems.isEmpty {
                        EmptyStateRow(title: "No ideas surfaced", detail: "Capture a thought or build a context pack so Terminal Brain has material to rank.", symbol: "lightbulb")
                    }
                }
                .darkPanel()
            }
            .frame(width: 520)

            VStack(alignment: .leading, spacing: 14) {
                if let item = selectedIdeaItem {
                    SectionTitle("Cheap Test", symbol: item.symbol)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: item.symbol)
                                .font(.title2)
                                .foregroundStyle(item.state.color)
                                .frame(width: 42, height: 42)
                                .background(item.state.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.white)
                                Text("\(item.project) - \(item.source)")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(item.state.color)
                            }
                            Spacer()
                            Text("\(item.score)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(item.state.color.opacity(0.18), in: Capsule())
                        }

                        Text(item.nextPrompt)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.86))
                            .fixedSize(horizontal: false, vertical: true)

                        Text(item.whyNow)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)

                        Text(item.detail)
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.58))
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)

                        if let path = item.path {
                            Text(path)
                                .font(.caption.monospaced())
                                .foregroundStyle(.white.opacity(0.44))
                                .lineLimit(2)
                                .textSelection(.enabled)
                        }

                        HStack {
                            Button {
                                Task { await model.askIdea(item) }
                            } label: {
                                Label(model.isAskingIdea ? "Testing" : "Pressure Test", systemImage: "sparkle.magnifyingglass")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(model.isAskingIdea)

                            Button {
                                Task { await model.askIdea(item, commit: true) }
                            } label: {
                                Label("Test + Commit", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.bordered)
                            .disabled(model.isAskingIdea)

                            Button {
                                model.workQuery = [item.project, item.title].filter { !$0.isEmpty && $0 != "General Brain" }.joined(separator: " - ")
                                selectedSection = "start"
                            } label: {
                                Label("Build Pack", systemImage: "shippingbox")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                model.quickIdea = "\(item.title)\n\nQuestion: \(item.nextPrompt)\n\nWhy now: \(item.whyNow)"
                                selectedSection = "focus"
                            } label: {
                                Label("Capture Test", systemImage: "tray.and.arrow.down")
                            }
                            .buttonStyle(.bordered)

                            if let path = item.path {
                                Button { model.openPath(path) } label: {
                                    Label("Open", systemImage: "arrow.up.right.square")
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        if !model.ideaAnswer.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label(model.ideaAnswerTitle.isEmpty ? "Idea Answer" : model.ideaAnswerTitle, systemImage: "text.bubble.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(item.state.color)
                                    Spacer()
                                    if !model.ideaOutput.isEmpty {
                                        Text(model.ideaOutput)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.white.opacity(0.46))
                                            .lineLimit(1)
                                    }
                                }
                                Text(model.ideaAnswer)
                                    .font(.callout)
                                    .foregroundStyle(.white.opacity(0.72))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                            }
                            .padding(12)
                            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.09), lineWidth: 1))
                        } else if !model.ideaOutput.isEmpty {
                            Text(model.ideaOutput)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.52))
                                .lineLimit(2)
                        }
                    }
                    .padding(16)
                    .darkPanel()
                }

                SectionTitle("Idea Operating Loop", symbol: "slider.horizontal.3")
                VStack(alignment: .leading, spacing: 10) {
                    PolicyLine("Captured thoughts must become a cheap test, a project link, or a dismissal.")
                    PolicyLine("Bubbling context is useful only when it changes a decision or next artifact.")
                    PolicyLine("Prefer tests small enough to run before the next broad planning pass.")
                    PolicyLine("Commit pressure-test answers so useful ideas become durable memory.")
                }
                .padding(14)
                .darkPanel()

                focusIdeaCapturePanel(focus)
            }
            .frame(minWidth: 680)
        }
    }

    private var oracleView: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Ask Terminal Brain", symbol: "sparkle.magnifyingglass")
                VStack(alignment: .leading, spacing: 14) {
                    TextField("What am I missing?", text: $model.oracleQuestion)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { Task { await model.askOracle() } }
                    HStack {
                        Button { Task { await model.askOracle() } } label: {
                            Label("Ask", systemImage: "return")
                        }
                        .buttonStyle(.borderedProminent)
                        Button {
                            model.workQuery = model.oracleQuestion
                            selectedSection = "start"
                        } label: {
                            Label("Start Work", systemImage: "shippingbox")
                        }
                        .buttonStyle(.bordered)
                        Button {
                            Task {
                                await model.commitOracleAnswer()
                                selectedSection = "review"
                            }
                        } label: {
                            Label("Commit", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.oracleAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Text(model.oracleMode.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(settings.theme.accent)
                    if !model.oracleCommitOutput.isEmpty {
                        Text(model.oracleCommitOutput)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(2)
                    }
                    Text(model.oracleAnswer)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                    if !model.oracleSuggestedActions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(model.oracleSuggestedActions.prefix(3), id: \.self) { action in
                                Button {
                                    applyOracleSuggestion(action)
                                } label: {
                                    Label(action, systemImage: symbolForOracleSuggestion(action))
                                        .lineLimit(1)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(16)
                .darkPanel()

                SectionTitle("Daily Oracle Brief", symbol: "text.bubble")
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(model.oracleBrief, id: \.self) { line in
                        OracleBriefLine(text: line)
                    }
                }
                .padding(14)
                .darkPanel()
            }
            .frame(width: 470)

            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Bubbling Up", symbol: "arrow.up.forward.circle")
                VStack(spacing: 0) {
                    ForEach(model.oracleItems) { item in
                        OracleCard(item: item, accent: settings.theme.accent) {
                            oracleActions(for: item)
                        }
                        if item.id != model.oracleItems.last?.id {
                            Divider().overlay(.white.opacity(0.08)).padding(.leading, 50)
                        }
                    }
                    if model.oracleItems.isEmpty {
                        EmptyStateRow(
                            title: "Nothing is bubbling yet",
                            detail: "Build a few context packs or sync more source material, then refresh.",
                            symbol: "sparkle.magnifyingglass"
                        )
                    }
                }
                .darkPanel()
            }
            .frame(minWidth: 620)
        }
    }

    private var reviewView: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionTitle("Oracle Review Queue", symbol: "tray.and.arrow.down.fill")
                    Spacer()
                    Button {
                        model.openOracleInbox()
                    } label: {
                        Label("Inbox", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                }
                Picker("Project Filter", selection: $reviewProjectFilter) {
                    Text("All Projects").tag("all")
                    ForEach(model.projects) { project in
                        Text(project.name).tag(project.name)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                VStack(spacing: 0) {
                    ForEach(filteredOracleCommits) { commit in
                        Button {
                            selectedCommitID = commit.id
                        } label: {
                            OracleCommitRow(commit: commit, selected: selectedOracleCommit?.id == commit.id)
                        }
                        .buttonStyle(.plain)
                        if commit.id != filteredOracleCommits.last?.id {
                            Divider().overlay(.white.opacity(0.08)).padding(.leading, 54)
                        }
                    }
                    if filteredOracleCommits.isEmpty {
                        EmptyStateRow(
                            title: reviewProjectFilter == "all" ? "No committed reads yet" : "No reads for this project",
                            detail: reviewProjectFilter == "all" ? "Ask Oracle, then use Commit to create reviewable memory." : "Commit a project update or ask the Project Oracle to create a read.",
                            symbol: "tray"
                        )
                    }
                }
                .darkPanel()
            }
            .frame(width: 460)

            VStack(alignment: .leading, spacing: 14) {
                if let commit = selectedOracleCommit {
                    SectionTitle("Review Detail", symbol: commit.status.symbol)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: commit.status.symbol)
                                .font(.title2)
                                .foregroundStyle(commit.status.color)
                                .frame(width: 38, height: 38)
                                .background(commit.status.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(commit.title)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.white)
                                Text("\(commit.project) - \(commit.source) - \(commit.created.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.callout)
                                    .foregroundStyle(.white.opacity(0.52))
                            }
                            Spacer()
                            StatusPill(text: commit.status.label, state: commit.status == .dismissed ? .off : .good)
                        }

                        if !commit.question.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Question")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.44))
                                    .textCase(.uppercase)
                                Text(commit.question)
                                    .font(.callout)
                                    .foregroundStyle(.white.opacity(0.72))
                                    .textSelection(.enabled)
                            }
                        }

                        Text(commit.preview)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.70))
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)

                        HStack(spacing: 8) {
                            ForEach(commit.tags.prefix(6), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.62))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.07), in: Capsule())
                            }
                        }

                        Text("Project: \(commit.project)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.52))

                        Text(commit.path)
                            .font(.caption.monospaced())
                            .foregroundStyle(.white.opacity(0.44))
                            .lineLimit(2)
                            .textSelection(.enabled)

                        HStack {
                            Button { model.openPath(commit.path) } label: { Label("Open", systemImage: "arrow.up.right.square") }
                            Button { model.setOracleCommitStatus(commit, status: .accepted) } label: { Label("Accept", systemImage: "checkmark.seal") }
                            Button { model.setOracleCommitStatus(commit, status: .linked) } label: { Label("Linked", systemImage: "link") }
                            Button {
                                model.delegateOracleCommitToStartWork(commit)
                                selectedSection = "start"
                            } label: { Label("Delegate", systemImage: "paperplane") }
                            Button { model.setOracleCommitStatus(commit, status: .dismissed) } label: { Label("Dismiss", systemImage: "xmark.circle") }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(16)
                    .darkPanel()
                } else {
                    EmptyStateRow(
                        title: "Select a committed read",
                        detail: "Committed Oracle answers will appear here as reviewable decisions and follow-ups.",
                        symbol: "tray.and.arrow.down"
                    )
                    .darkPanel()
                }

                SectionTitle("Review Operating Loop", symbol: "arrow.triangle.2.circlepath")
                VStack(alignment: .leading, spacing: 10) {
                    PolicyLine("Accepted means the read is useful and should influence work.")
                    PolicyLine("Linked means it has been connected to the right project, note, or daily plan.")
                    PolicyLine("Delegated means it should become an agent handoff or Start Work pack.")
                    PolicyLine("Dismissed means it was noise and should not keep resurfacing.")
                }
                .padding(14)
                .darkPanel()
            }
            .frame(minWidth: 620)
        }
    }

    private var projectsView: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionTitle("Project Memory", symbol: "folder.fill.badge.gearshape")
                    Spacer()
                    if !model.projectMemoryCopyOutput.isEmpty {
                        Text(model.projectMemoryCopyOutput)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.48))
                            .lineLimit(1)
                    }
                    Button {
                        Task { await model.copyProjectMemory() }
                    } label: {
                        Label("Copy", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                VStack(spacing: 0) {
                    ForEach(model.projects) { project in
                        Button {
                            selectedProjectID = project.id
                        } label: {
                            ProjectMemoryRow(project: project, selected: selectedProject?.id == project.id)
                        }
                        .buttonStyle(.plain)
                        if project.id != model.projects.last?.id {
                            Divider().overlay(.white.opacity(0.08)).padding(.leading, 54)
                        }
                    }
                    if model.projects.isEmpty {
                        EmptyStateRow(
                            title: "No project memory yet",
                            detail: "Build context packs or commit Oracle reads to populate project pages.",
                            symbol: "folder"
                        )
                    }
                }
                .darkPanel()
            }
            .frame(width: 460)

            VStack(alignment: .leading, spacing: 14) {
                if let project = selectedProject {
                    SectionTitle(project.name, symbol: project.symbol)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: project.symbol)
                                .font(.title2)
                                .foregroundStyle(project.accent)
                                .frame(width: 42, height: 42)
                                .background(project.accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.name)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.white)
                                Text(project.lastActivity == Date.distantPast ? "No dated activity yet" : "Last activity \(project.lastActivity.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.callout)
                                    .foregroundStyle(.white.opacity(0.52))
                            }
                            Spacer()
                            StatusPill(text: "\(project.signalCount) signals", state: project.signalCount > 0 ? .good : .off)
                        }

                        Text(project.summary)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.70))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 10) {
                            SourceInfoPill(title: "Packs", value: "\(project.contextPacks.count)", symbol: "shippingbox")
                            SourceInfoPill(title: "Reads", value: "\(project.oracleCommits.count)", symbol: "tray.and.arrow.down")
                            SourceInfoPill(title: "Loops", value: "\(project.openLoops.count)", symbol: "checklist")
                            SourceInfoPill(title: "Delegated", value: "\(project.delegatedCount)", symbol: "paperplane")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recommended Next Action")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.44))
                                .textCase(.uppercase)
                            Text(project.recommendedAction)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.86))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack {
                            Button {
                                Task {
                                    await model.buildPack(for: project)
                                    selectedSection = "start"
                                }
                            } label: {
                                Label("Build Pack", systemImage: "shippingbox")
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                Task {
                                    await model.askOracle(for: project)
                                    selectedSection = "oracle"
                                }
                            } label: {
                                Label("Ask Oracle", systemImage: "sparkle.magnifyingglass")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                Task { await model.commitProjectUpdate(project) }
                            } label: {
                                Label("Commit Update", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.bordered)

                            if let latest = project.contextPacks.first, let path = latest.path {
                                Button {
                                    model.openPath(path)
                                } label: {
                                    Label("Latest Pack", systemImage: "doc.richtext")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding(16)
                    .darkPanel()

                    ProjectSignalSection(title: "Oracle Reads", symbol: "tray.and.arrow.down.fill") {
                        ForEach(project.oracleCommits) { commit in
                            OracleCommitRow(commit: commit, selected: false)
                        }
                        if project.oracleCommits.isEmpty {
                            EmptyStateRow(title: "No committed reads", detail: "Commit useful Oracle answers to attach them to this project.", symbol: "tray")
                        }
                    }

                    ProjectSignalSection(title: "Context Packs", symbol: "shippingbox.fill") {
                        ForEach(project.contextPacks) { pack in
                            FeedListRow(item: pack, selected: false)
                        }
                        if project.contextPacks.isEmpty {
                            EmptyStateRow(title: "No context packs", detail: "Use Build Pack to prepare an agent handoff for this project.", symbol: "shippingbox")
                        }
                    }

                    ProjectSignalSection(title: "Open Loops And Decisions", symbol: "checklist") {
                        ForEach(project.openLoops + project.decisions) { item in
                            OracleCard(item: item, accent: project.accent) {
                                EmptyView()
                            }
                        }
                        if project.openLoops.isEmpty && project.decisions.isEmpty {
                            EmptyStateRow(title: "No loop signals", detail: "Open loops and decisions will appear here as the Oracle extracts them.", symbol: "checklist")
                        }
                    }
                } else {
                    EmptyStateRow(
                        title: "Select a project",
                        detail: "Project pages collect context packs, Oracle reads, open loops, and decisions into one working surface.",
                        symbol: "folder.fill.badge.gearshape"
                    )
                    .darkPanel()
                }
            }
            .frame(minWidth: 700)
        }
    }

    private var memoryBriefView: some View {
        let agentSource = model.sources.first { $0.id == "agent-history" }
        let agentCard = healthCard(named: "Agent Histories")
        return HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Agent Memory", symbol: "brain.head.profile")
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundStyle(agentCard?.state.color ?? .green)
                            .frame(width: 42, height: 42)
                            .background((agentCard?.state.color ?? .green).opacity(0.16), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Codex / Claude Continuity")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                            Text(agentCard?.value ?? agentSource?.status ?? "derived memory")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(agentCard?.state.color ?? .green)
                        }
                        Spacer()
                        StatusPill(text: "Raw guarded", state: .good)
                    }

                    Text(agentSource?.detail ?? "Derived work memory from prior agent sessions. Raw transcripts stay out of normal search; useful findings are promoted into reviewable memory.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.70))
                        .fixedSize(horizontal: false, vertical: true)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                        if let agentSource {
                            ForEach(agentSource.metrics) { metric in
                                SourceMetricTile(metric: metric, accent: agentSource.state.color)
                            }
                        } else {
                            SourceInfoPill(title: "Mode", value: "Derived", symbol: "list.bullet.rectangle")
                            SourceInfoPill(title: "Raw", value: "Guarded", symbol: "lock.shield")
                        }
                    }

                    HStack(spacing: 10) {
                        Button {
                            Task { await model.copyMemoryBrief() }
                        } label: {
                            Label("Copy Memory Brief", systemImage: "doc.on.clipboard")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            Task { await model.copySourceInventory() }
                        } label: {
                            Label("Copy Sources", systemImage: "tray.full")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Task { await model.copyProjectMemory() }
                        } label: {
                            Label("Copy Projects", systemImage: "folder.fill.badge.gearshape")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Task { await model.copyAgentPrompt() }
                        } label: {
                            Label("Agent Prompt", systemImage: "paperplane.fill")
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack(spacing: 10) {
                        Stepper("Lead \(memoryLeadIndex)", value: $memoryLeadIndex, in: 1...25)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.76))
                            .frame(width: 128, alignment: .leading)

                        Button {
                            Task { await model.previewMemoryLead(index: memoryLeadIndex) }
                        } label: {
                            Label("Preview", systemImage: "eye")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Task { await model.promoteMemoryLead(index: memoryLeadIndex) }
                        } label: {
                            Label("Promote", systemImage: "tray.and.arrow.down.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    HStack(spacing: 10) {
                        Stepper("Recent \(recentWorkIndex)", value: $recentWorkIndex, in: 1...25)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.76))
                            .frame(width: 128, alignment: .leading)

                        Button {
                            Task { await model.previewRecentWork(index: recentWorkIndex) }
                        } label: {
                            Label("Preview Work", systemImage: "clock.badge.checkmark")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Task { await model.promoteRecentWork(index: recentWorkIndex) }
                        } label: {
                            Label("Promote Work", systemImage: "arrow.up.doc.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if !model.memoryBriefCopyOutput.isEmpty || !model.sourceInventoryCopyOutput.isEmpty || !model.projectMemoryCopyOutput.isEmpty {
                        Text(!model.memoryBriefCopyOutput.isEmpty ? model.memoryBriefCopyOutput : (!model.sourceInventoryCopyOutput.isEmpty ? model.sourceInventoryCopyOutput : model.projectMemoryCopyOutput))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.50))
                    }
                    if !model.memoryPromoteOutput.isEmpty {
                        Text(model.memoryPromoteOutput)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.58))
                    }
                    if !model.recentWorkPromoteOutput.isEmpty {
                        Text(model.recentWorkPromoteOutput)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.58))
                    }
                }
                .padding(16)
                .darkPanel()

                ProjectSignalSection(title: "Operating Policy", symbol: "lock.shield.fill") {
                    PolicyLine("Use derived memory for continuity; do not make raw transcripts normal search input.")
                    PolicyLine("Promote useful agent history or recent shipped work into Oracle Inbox before it becomes invisible context.")
                    PolicyLine("Use `make work-block` after promotion so old history becomes action, not archive.")
                }
            }
            .frame(width: 520)

            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Active Project Memory", symbol: "folder.fill.badge.gearshape")
                VStack(spacing: 0) {
                    ForEach(model.projects.prefix(8)) { project in
                        Button {
                            selectedProjectID = project.id
                            selectedSection = "projects"
                        } label: {
                            ProjectMemoryRow(project: project, selected: false)
                        }
                        .buttonStyle(.plain)
                        if project.id != model.projects.prefix(8).last?.id {
                            Divider().overlay(.white.opacity(0.08)).padding(.leading, 54)
                        }
                    }
                    if model.projects.isEmpty {
                        EmptyStateRow(title: "No project memory yet", detail: "Run sync or build a context pack to populate project pages.", symbol: "folder")
                    }
                }
                .darkPanel()

                SectionTitle("Use It", symbol: "sparkles")
                VStack(alignment: .leading, spacing: 10) {
                    PolicyLine("Run `make memory` to review derived continuity leads without opening the app.")
                    PolicyLine("Copy Memory Brief for a prompt-ready handoff to Codex or Claude.")
                    PolicyLine("Copy Sources when you need proof of what local memory stores are visible.")
                }
                .padding(14)
                .darkPanel()
            }
            .frame(minWidth: 560)
        }
    }

    private var feedView: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Activity Feed", symbol: "list.bullet.rectangle.portrait.fill")
                Picker("Feed Filter", selection: $feedFilter) {
                    ForEach(FeedKind.allCases) { filter in
                        Text("\(filter.label) \(feedCount(for: filter))").tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                VStack(spacing: 0) {
                    ForEach(filteredFeedItems) { item in
                        Button {
                            selectedFeedID = item.id
                        } label: {
                            FeedListRow(item: item, selected: selectedFeedItem?.id == item.id)
                        }
                        .buttonStyle(.plain)
                        if item.id != filteredFeedItems.last?.id {
                            Divider().overlay(.white.opacity(0.08)).padding(.leading, 54)
                        }
                    }
                    if filteredFeedItems.isEmpty {
                        EmptyStateRow(
                            title: "No matching activity",
                            detail: "This filter has no current items. Build a pack, run sync, or refresh status.",
                            symbol: "line.3.horizontal.decrease.circle"
                        )
                    }
                }
                .darkPanel()
            }
            .frame(width: 430)

            VStack(alignment: .leading, spacing: 14) {
                if let item = selectedFeedItem {
                    SectionTitle("Selected Item", symbol: item.symbol)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: item.symbol)
                                .font(.title2)
                                .foregroundStyle(item.state.color)
                                .frame(width: 38, height: 38)
                                .background(item.state.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.white)
                                Text("\(item.subtitle) - \(item.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.callout)
                                    .foregroundStyle(.white.opacity(0.52))
                            }
                            Spacer()
                            StatusPill(text: item.state.rawValue, state: item.state)
                        }

                        Text(item.detail)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)

                        if let path = item.path {
                            Text(path)
                                .font(.caption.monospaced())
                                .foregroundStyle(.white.opacity(0.44))
                                .lineLimit(2)
                                .textSelection(.enabled)
                            HStack {
                                Button { model.openPath(path) } label: {
                                    Label("Open", systemImage: "arrow.up.right.square")
                                }
                                Button { model.openWorkspace() } label: {
                                    Label("Workspace", systemImage: "folder")
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(16)
                    .darkPanel()
                } else {
                    Text("Run refresh or build a context pack to populate the feed.")
                        .foregroundStyle(.white.opacity(0.58))
                        .padding(16)
                        .darkPanel()
                }

                SectionTitle("Feed Actions", symbol: "sparkles")
                HStack(spacing: 10) {
                    Button {
                        Task { await model.startWork() }
                    } label: {
                        Label("Build Pack", systemImage: "shippingbox")
                    }
                    .disabled(model.isBuildingContextPack)
                    .buttonStyle(.borderedProminent)

                    Button {
                        Task { await model.runSyncNow() }
                    } label: {
                        Label("Run Sync", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(model.isSyncing)
                    .buttonStyle(.bordered)

                    Button {
                        Task { await model.refresh() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
                syncOutput
            }
            .frame(minWidth: 520)
        }
    }

    private var sourcesView: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Permissioned Sources", symbol: "tray.full.fill")
                VStack(spacing: 0) {
                    ForEach(model.sources) { source in
                        Button {
                            selectedSourceID = source.id
                        } label: {
                            SourceListRow(source: source, selected: selectedSource?.id == source.id)
                        }
                        .buttonStyle(.plain)
                        if source.id != model.sources.last?.id {
                            Divider().overlay(.white.opacity(0.08)).padding(.leading, 48)
                        }
                    }
                }
                .darkPanel()
            }
            .frame(width: 470)
            VStack(alignment: .leading, spacing: 14) {
                if let source = selectedSource {
                    SectionTitle("Source Detail", symbol: source.symbol)
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: source.symbol)
                                .font(.title2)
                                .foregroundStyle(source.state.color)
                                .frame(width: 38, height: 38)
                                .background(source.state.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(source.name)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.white)
                                Text(source.status)
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(source.state.color)
                            }
                            Spacer()
                            if source.isSensitive {
                                Label("Sensitive", systemImage: "lock.shield.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(.orange.opacity(0.12), in: Capsule())
                            }
                        }

                        Text(source.detail)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 10) {
                            SourceInfoPill(title: "Mode", value: source.mode, symbol: "slider.horizontal.3")
                            SourceInfoPill(title: "Permission", value: source.permission, symbol: "lock.shield")
                            SourceInfoPill(title: "State", value: source.state.rawValue, symbol: "waveform.path.ecg")
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                            ForEach(source.metrics) { metric in
                                SourceMetricTile(metric: metric, accent: source.state.color)
                            }
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Location")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.44))
                                .textCase(.uppercase)
                            Text(source.location)
                                .font(.caption.monospaced())
                                .foregroundStyle(.white.opacity(0.52))
                                .lineLimit(2)
                                .textSelection(.enabled)
                        }

                        sourceActionButtons(for: source)
                    }
                    .padding(16)
                    .darkPanel()
                }

                sourceControls
                SectionTitle("Source Policy", symbol: "lock.shield")
                VStack(alignment: .leading, spacing: 10) {
                    PolicyLine("Apple Notes is explicit-only and never read at startup.")
                    PolicyLine("Drafts bridge stays manual until you intentionally enable it.")
                    PolicyLine("Obsidian and derived agent memory are safe default surfaces.")
                    PolicyLine("Mission Control is remote compute, not a permission owner.")
                }
                .padding(12)
                .darkPanel()
            }
            .frame(minWidth: 560)
        }
    }

    private var briefingView: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Command Queue", symbol: "sun.max.fill")
                VStack(spacing: 0) {
                    ForEach(model.dailyCommands) { item in
                        DailyCommandRow(item: item)
                        if item.id != model.dailyCommands.last?.id {
                            Divider().overlay(.white.opacity(0.08)).padding(.leading, 48)
                        }
                    }
                    if model.dailyCommands.isEmpty {
                        EmptyStateRow(title: "No command items", detail: "Refresh or ask Oracle to surface the next useful move.", symbol: "sun.max")
                    }
                }
                .darkPanel()
            }
            .frame(minWidth: 620)
            VStack(alignment: .leading, spacing: 14) {
                if let first = model.dailyCommands.first {
                    SectionTitle("Do First", symbol: first.symbol)
                    VStack(alignment: .leading, spacing: 14) {
                        StatusPill(text: first.priority, state: first.state)
                        Text(first.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text(first.detail)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                        HStack {
                            Button {
                                applyDailyCommand(first)
                            } label: {
                                Label(first.action, systemImage: "arrow.right.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            Button {
                                model.oracleQuestion = "What should I do first for \(first.project)?"
                                selectedSection = "oracle"
                            } label: {
                                Label("Ask", systemImage: "sparkle.magnifyingglass")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(16)
                    .darkPanel()
                }

                SectionTitle("Daily Baseline", symbol: "checklist")
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(model.briefing) { item in
                        BriefingRow(item: item)
                    }
                }
                .darkPanel()
            }
            .frame(width: 390)
        }
    }

    private var startWorkView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 16) {
                Text("What are we working on?")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                HStack(spacing: 12) {
                    TextField("Project, repo, task, or question", text: $model.workQuery)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        Task { await model.startWork() }
                    } label: {
                        Label(model.isBuildingContextPack ? "Building" : "Build Pack", systemImage: "shippingbox")
                    }
                    .disabled(model.isBuildingContextPack || model.workQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.borderedProminent)
                    Button { model.openLatestContextPack() } label: {
                        Label("Open Latest", systemImage: "doc.richtext")
                    }
                    .buttonStyle(.bordered)
                }
                if !model.latestContextPackPath.isEmpty {
                    Text(model.latestContextPackPath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.white.opacity(0.50))
                        .lineLimit(1)
                        .textSelection(.enabled)
                }
            }
            .padding(16)
            .darkPanel()
            startWorkOutput
        }
    }

    private var systemView: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
            SystemSurfaceCard(title: "Menu Bar Extra", value: "Installed", detail: "Quick status, refresh, sync, logs, and Mission Control.", symbol: "menubar.rectangle")
            SystemSurfaceCard(title: "Settings Scene", value: "Native", detail: "Appearance, control API, and permission policy live in the macOS Settings window.", symbol: "gearshape")
            SystemSurfaceCard(title: "Control API", value: "127.0.0.1:8765", detail: "Local-only gateway for agents and MCP.", symbol: "network")
            SystemSurfaceCard(title: "Widget", value: "Next", detail: "A desktop/Notification Center widget should show prompt-safety, sync age, and Mission points.", symbol: "rectangle.on.rectangle")
            SystemSurfaceCard(title: "Login Item", value: "Next", detail: "Launch at login after the gateway has a signed release bundle.", symbol: "power")
            SystemSurfaceCard(title: "Shortcuts", value: "Native", detail: "App Shortcuts expose Copy Now, Copy Sources, Copy Memory, Copy Process Map, Copy Cleanup Plan, Copy Support Bundle, Copy Handoff, Copy Start Here, Copy Prompt, Copy Oracle Digest, Commit Outcome, Copy Value, Copy Deck, Copy Snapshot, Copy Blindspots, Copy Ideas, Run Sync, Start Work, and Open/Copy Latest Context Pack to Spotlight, Siri, and automation.", symbol: "wand.and.stars")
        }
    }

    private func feedCount(for filter: FeedKind) -> Int {
        if filter == .all {
            return model.feedItems.count
        }
        return model.feedItems.filter { $0.kind == filter }.count
    }

    @ViewBuilder
    private func oracleActions(for item: OracleItem) -> some View {
        HStack(spacing: 8) {
            Button {
                model.workQuery = item.title
                selectedSection = "start"
            } label: {
                Label("Pack", systemImage: "shippingbox")
            }
            Button {
                model.promoteOracleItem(item)
            } label: {
                Label("Promote", systemImage: "pin")
            }
            if let path = item.path {
                Button {
                    model.openPath(path)
                } label: {
                    Label("Open", systemImage: "arrow.up.right.square")
                }
            }
        }
        .buttonStyle(.bordered)
    }

    private func inferredContextQuery() -> String {
        var query = commandQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return "" }
        let lower = query.lowercased()
        let prefixes = [
            "build context pack for ",
            "build context pack ",
            "context pack for ",
            "start work on ",
            "start work ",
            "pack for "
        ]
        var matchedPrefix = false
        for prefix in prefixes where lower.hasPrefix(prefix) {
            query = String(query.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            matchedPrefix = true
            break
        }
        return matchedPrefix ? query : ""
    }

    private func applyCommand(_ command: BrainCommand) {
        showCommandPalette = false
        switch command.action {
        case .section(let section):
            selectedSection = section
        case .source(let id):
            selectedSourceID = id
            selectedSection = "sources"
        case .feed(let id, let kind):
            selectedFeedID = id
            feedFilter = kind
            selectedSection = "feed"
        case .commit(let id):
            selectedCommitID = id
            selectedSection = "review"
        case .radar(let id):
            selectedRadarID = id
            selectedSection = "radar"
        case .blindspot(let id):
            selectedBlindspotID = id
            selectedSection = "blindspots"
        case .idea(let id):
            selectedIdeaID = id
            selectedSection = "ideas"
        case .project(let id):
            selectedProjectID = id
            selectedSection = "projects"
        case .openMission:
            model.openMissionControl()
        case .openLogs:
            model.openLogs()
        case .openWorkspace:
            model.openWorkspace()
        case .openPath(let path):
            model.openPath(path)
        case .runSync:
            Task { await model.runSyncNow() }
        case .copySnapshot:
            Task { await model.copyOperatorSnapshot() }
        case .copyFirstMinute:
            Task { await model.copyFirstMinute() }
        case .copyDemo:
            Task { await model.copyDemo() }
        case .copyPlaybook:
            Task { await model.copyPlaybook() }
        case .copyValueAudit:
            Task { await model.copyValueAudit() }
        case .copyNow:
            Task { await model.copyNow() }
        case .copyProcessMap:
            Task { await model.copyProcessMap() }
        case .copyCleanupPlan:
            Task { await model.copyCleanupPlan() }
        case .copySupportBundle:
            Task { await model.copySupportBundle() }
        case .copyUseNow:
            Task { await model.copyUseNow() }
        case .copyWorkBlock:
            Task { await model.copyWorkBlock() }
        case .copyStartHere:
            Task { await model.copyStartHere() }
        case .copyValueBrief:
            Task { await model.copyValueBrief() }
        case .copyOracleBrief:
            Task { await model.copyOracleBrief() }
        case .copyOracleDigest:
            Task { await model.copyOracleDigest() }
        case .copyBrief:
            Task { await model.copyOperatorBrief() }
        case .copyDecisionLane:
            Task { await model.copyDecisionLane() }
        case .copyBlindspots:
            Task { await model.copyBlindspotBrief() }
        case .copyIdeas:
            Task { await model.copyIdeaPulse() }
        case .copyProjectMemory:
            Task { await model.copyProjectMemory() }
        case .copySourceInventory:
            Task { await model.copySourceInventory() }
        case .copyMemoryBrief:
            Task { await model.copyMemoryBrief() }
        case .promoteRecentWork:
            selectedSection = "memory"
            Task { await model.promoteRecentWork(index: 1) }
        case .copyDeck:
            Task { await model.copyOperatorDeck() }
        case .copyAgentPrompt:
            Task { await model.copyAgentPrompt() }
        case .copyLatestPack:
            Task { await model.copyLatestContextPack() }
        case .copyHandoff:
            Task { await model.copyHandoff() }
        case .askOracle(let question):
            model.oracleQuestion = question
            selectedSection = "oracle"
            Task { await model.askOracle() }
        case .askFocus:
            selectedSection = "focus"
            Task { await model.askFocusOracle(model.focusItem) }
        case .draftIdea(let idea):
            model.quickIdea = idea
            selectedSection = "focus"
        case .buildContext(let query):
            model.workQuery = query
            selectedSection = "start"
            Task { await model.startWork() }
        }
    }

    private func applyDailyCommand(_ item: DailyCommandItem) {
        if let radar = model.radarItems.first(where: { $0.query == item.query || $0.title == item.title }) {
            applyRadarAction(radar)
            return
        }
        if item.action == "Open Review" {
            reviewProjectFilter = item.project.isEmpty ? "all" : item.project
            selectedSection = "review"
            return
        }
        if item.action == "Open Project", let project = model.projects.first(where: { $0.name == item.project }) {
            selectedProjectID = project.id
            selectedSection = "projects"
            return
        }
        if item.action == "Open Pack", let pack = model.feedItems.first(where: { $0.title == item.query }), let path = pack.path {
            model.openPath(path)
            return
        }
        if item.action == "Open System" {
            selectedSection = "system"
            return
        }
        if item.action == "Ask Oracle" {
            model.oracleQuestion = item.query
            selectedSection = "oracle"
            return
        }
        model.workQuery = item.query
        selectedSection = "start"
    }

    private func applyFocusAction(_ item: FocusItem) {
        if let radar = model.radarItems.first(where: { $0.id == item.id }) {
            applyRadarAction(radar)
            return
        }
        let command = DailyCommandItem(
            id: item.id,
            title: item.title,
            detail: item.detail,
            priority: item.score > 0 ? "\(item.score)" : "Focus",
            action: item.action,
            project: item.project,
            symbol: item.symbol,
            state: item.state,
            query: item.query
        )
        applyDailyCommand(command)
    }

    private func applyOperatorBrief(_ item: OperatorBriefItem) {
        let command = DailyCommandItem(
            id: item.id,
            title: item.title,
            detail: item.detail,
            priority: item.label,
            action: item.action,
            project: item.project,
            symbol: item.symbol,
            state: item.state,
            query: item.query
        )
        applyDailyCommand(command)
    }

    private func askFocusOracle(_ item: FocusItem, intent: String? = nil) {
        let question = intent.map { model.focusOracleQuestion(for: item, intent: $0) } ?? model.oracleQuestion
        Task {
            await model.askFocusOracle(item, question: question)
        }
    }

    private func applyOracleSuggestion(_ suggestion: String) {
        let lower = suggestion.lowercased()
        if lower.contains("commit") {
            Task { await model.commitOracleAnswer(project: model.focusItem.project) }
            selectedSection = "review"
        } else if lower.contains("context pack") || lower.contains("start work") {
            let focusQuery = model.focusItem.query.trimmingCharacters(in: .whitespacesAndNewlines)
            model.workQuery = focusQuery.isEmpty ? model.oracleQuestion : focusQuery
            selectedSection = "start"
        } else if lower.contains("sync") {
            Task { await model.runSyncNow() }
        } else {
            model.quickIdea = suggestion
            selectedSection = "focus"
        }
    }

    private func symbolForOracleSuggestion(_ suggestion: String) -> String {
        let lower = suggestion.lowercased()
        if lower.contains("commit") { return "square.and.arrow.down" }
        if lower.contains("context") || lower.contains("start work") { return "shippingbox" }
        if lower.contains("sync") { return "arrow.triangle.2.circlepath" }
        if lower.contains("mission") { return "display" }
        return "arrow.right.circle"
    }

    private func applyBlindspotAction(_ item: BlindspotItem) {
        switch item.nextAction {
        case "Review":
            selectedCommitID = item.sourceID
            reviewProjectFilter = item.project.isEmpty ? "all" : item.project
            selectedSection = "review"
        case "Open Project":
            if let project = model.projects.first(where: { $0.name == item.project || $0.id == item.sourceID }) {
                selectedProjectID = project.id
            }
            selectedSection = "projects"
        case "Open System", "Open Settings":
            selectedSection = "setup"
        case "Capture Idea":
            model.quickIdea = item.question
            selectedSection = "focus"
        case "Ask Oracle":
            Task { await model.askBlindspot(item) }
        default:
            model.workQuery = [item.project, item.question].filter { !$0.isEmpty && $0 != "General Brain" }.joined(separator: " - ")
            selectedSection = "start"
        }
    }

    private func applyRadarAction(_ item: RadarItem) {
        switch item.action {
        case "Open Review":
            markRadarActed(item)
            reviewProjectFilter = item.project.isEmpty ? "all" : item.project
            selectedSection = "review"
        case "Open Project":
            markRadarActed(item)
            if let project = model.projects.first(where: { $0.name == item.project }) {
                selectedProjectID = project.id
            }
            selectedSection = "projects"
        case "Open Pack":
            markRadarActed(item)
            if let path = item.path {
                model.openPath(path)
            }
        case "Open Sources":
            markRadarActed(item)
            selectedSection = "sources"
        case "Open Settings":
            markRadarActed(item)
            selectedSection = "setup"
        case "Ask Oracle":
            model.oracleQuestion = item.query
            selectedSection = "oracle"
        default:
            markRadarActed(item)
            model.workQuery = item.query
            selectedSection = "start"
        }
    }

    private func markRadarActed(_ item: RadarItem) {
        if item.disposition == .fresh || item.disposition == .watching {
            model.setRadarDisposition(item, disposition: .acted)
        }
    }

    @ViewBuilder
    private func sourceActionButtons(for source: BrainSource) -> some View {
        HStack(spacing: 10) {
            switch source.id {
            case "obsidian":
                Button { model.openWorkspace() } label: { Label("Open Vault", systemImage: "folder") }
                Button { Task { await model.runSyncNow() } } label: { Label("Sync", systemImage: "arrow.triangle.2.circlepath") }
                    .disabled(model.isSyncing)
            case "agent-history":
                Button { model.openPath(Paths.agentHistoryStatsJSON) } label: { Label("Stats", systemImage: "doc.text") }
                Button { selectedSection = "feed" } label: { Label("Feed", systemImage: "list.bullet.rectangle") }
            case "drafts":
                Button { model.openLogs() } label: { Label("Logs", systemImage: "doc.text") }
                Button { selectedSection = "start" } label: { Label("Build Pack", systemImage: "shippingbox") }
            case "apple-notes":
                Button { model.checkAppleNotesPermission() } label: { Label("Check Permission", systemImage: "lock.shield") }
                Button { Task { await model.runSyncNow() } } label: { Label("Manual Sync", systemImage: "arrow.triangle.2.circlepath") }
                    .disabled(model.isSyncing)
            case "mission":
                Button { model.openMissionControl() } label: { Label("Open Mission", systemImage: "display") }
                Button { Task { await model.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
            default:
                Button { Task { await model.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
            }
        }
        .buttonStyle(.bordered)
    }

    private var sourceControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Source Controls", symbol: "switch.2")
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Include Apple Notes only for manual sync", isOn: $model.appleNotesEnabledForManualSync)
                    .foregroundStyle(.white.opacity(0.86))
                Text("Startup checks never read Notes. This only affects the Run Sync button in Terminal Brain.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.50))
                Text(model.appleNotesPermissionMessage)
                    .font(.caption.monospaced())
                    .foregroundStyle(.white.opacity(0.44))
                    .lineLimit(3)
                HStack {
                    Button { model.checkAppleNotesPermission() } label: { Label("Notes", systemImage: "lock.shield") }
                    Button { model.openMissionControl() } label: { Label("Mission", systemImage: "display") }
                    Button { model.openLogs() } label: { Label("Logs", systemImage: "doc.text") }
                    Button { model.openWorkspace() } label: { Label("Vault", systemImage: "folder") }
                }
                .buttonStyle(.bordered)
            }
            .padding(12)
            .darkPanel()
        }
    }

    @ViewBuilder
    private var syncOutput: some View {
        if !model.syncOutput.isEmpty {
            TerminalOutput(title: "Latest Sync Output", text: model.syncOutput)
        }
    }

    @ViewBuilder
    private var startWorkOutput: some View {
        if !model.startWorkOutput.isEmpty {
            TerminalOutput(title: "Context Pack Output", text: model.startWorkOutput)
        }
    }
}

enum BrainCommandAction {
    case section(String)
    case source(String)
    case feed(String, FeedKind)
    case commit(String)
    case radar(String)
    case blindspot(String)
    case idea(String)
    case project(String)
    case openMission
    case openLogs
    case openWorkspace
    case openPath(String)
    case runSync
    case copySnapshot
    case copyFirstMinute
    case copyDemo
    case copyPlaybook
    case copyValueAudit
    case copyNow
    case copyProcessMap
    case copyCleanupPlan
    case copySupportBundle
    case copyUseNow
    case copyWorkBlock
    case copyStartHere
    case copyValueBrief
    case copyOracleBrief
    case copyOracleDigest
    case copyBrief
    case copyDecisionLane
    case copyBlindspots
    case copyIdeas
    case copyProjectMemory
    case copySourceInventory
    case copyMemoryBrief
    case promoteRecentWork
    case copyDeck
    case copyAgentPrompt
    case copyLatestPack
    case copyHandoff
    case askOracle(String)
    case askFocus
    case draftIdea(String)
    case buildContext(String)
}

struct BrainCommand: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let category: String
    let action: BrainCommandAction
}

struct CommandPaletteView: View {
    @Binding var query: String
    let items: [BrainCommand]
    let accent: Color
    let onCancel: () -> Void
    let onSelect: (BrainCommand) -> Void
    @FocusState private var focused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.34)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "command")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(accent)
                    TextField("Search commands, sources, context packs, or actions", text: $query)
                        .textFieldStyle(.plain)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .focused($focused)
                        .onSubmit {
                            if let first = items.first {
                                onSelect(first)
                            }
                        }
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.64))
                            .frame(width: 24, height: 24)
                            .background(.white.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)

                Divider().overlay(.white.opacity(0.10))

                ScrollView {
                    VStack(spacing: 2) {
                        if items.isEmpty {
                            EmptyStateRow(
                                title: "No command found",
                                detail: "Try source names, feed categories, Mission, sync, logs, or a context-pack phrase.",
                                symbol: "magnifyingglass"
                            )
                        } else {
                            ForEach(items.prefix(12)) { item in
                                Button {
                                    onSelect(item)
                                } label: {
                                    CommandRow(command: item, accent: accent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 520)

                Divider().overlay(.white.opacity(0.08))

                HStack {
                    Label("Return runs first result", systemImage: "return")
                    Spacer()
                    Text("\(items.count) result\(items.count == 1 ? "" : "s")")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.42))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .frame(width: 720)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.16), lineWidth: 1))
            .shadow(color: .black.opacity(0.38), radius: 42, x: 0, y: 24)
            .padding(.top, 68)
        }
        .onAppear {
            focused = true
        }
    }
}

struct CommandRow: View {
    let command: BrainCommand
    let accent: Color

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: command.symbol)
                .font(.headline)
                .foregroundStyle(accent)
                .frame(width: 30, height: 30)
                .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(command.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(command.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.50))
                    .lineLimit(1)
            }
            Spacer()
            Text(command.category)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.48))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.white.opacity(0.07), in: Capsule())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(.white.opacity(0.001), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct NavRow: View {
    let title: String
    let symbol: String
    let badge: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol).frame(width: 18)
                Text(title)
                Spacer()
                if !badge.isEmpty {
                    Text(badge)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(.white.opacity(0.12), in: Capsule())
                }
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(selected ? Color.white : Color.white.opacity(0.72))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selected ? Color.white.opacity(0.14) : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct MiniStatus: View {
    let label: String
    let value: String
    let symbol: String

    var body: some View {
        Label {
            HStack {
                Text(label)
                Spacer()
                Text(value).foregroundStyle(.white.opacity(0.72))
            }
        } icon: {
            Image(systemName: symbol)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.white.opacity(0.62))
    }
}

struct SectionTitle: View {
    let title: String
    let symbol: String

    init(_ title: String, symbol: String) {
        self.title = title
        self.symbol = symbol
    }

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white.opacity(0.88))
    }
}

struct HealthRow: View {
    let card: HealthCard

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: card.symbol)
                .font(.title3)
                .foregroundStyle(card.state.color)
                .frame(width: 28, height: 28)
                .background(card.state.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(card.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                Text(card.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(card.value)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.white)
                Text(card.state.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(card.state.color)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct SetupStepRow: View {
    let step: SetupStep

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: step.symbol)
                .font(.title3)
                .foregroundStyle(step.state.color)
                .frame(width: 30, height: 30)
                .background(step.state.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(step.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(step.state.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(step.state.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(step.state.color.opacity(0.13), in: Capsule())
                }
                Text(step.detail)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
                Text(step.action)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.44))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

struct FeedListRow: View {
    let item: BrainFeedItem
    let selected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.symbol)
                .font(.title3)
                .foregroundStyle(item.state.color)
                .frame(width: 30, height: 30)
                .background(item.state.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Text(item.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.44))
                }
                Text(item.subtitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(item.state.color)
                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.50))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(selected ? Color.white.opacity(0.10) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct OracleCommitRow: View {
    let commit: OracleCommit
    let selected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: commit.status.symbol)
                .font(.title3)
                .foregroundStyle(commit.status.color)
                .frame(width: 30, height: 30)
                .background(commit.status.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(commit.title)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Text(commit.created.formatted(date: .omitted, time: .shortened))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.44))
                }
                Text(commit.status.label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(commit.status.color)
                Text(commit.project)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.44))
                    .lineLimit(1)
                Text(commit.preview)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.50))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(selected ? Color.white.opacity(0.10) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct ProjectMemoryRow: View {
    let project: ProjectMemory
    let selected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: project.symbol)
                .font(.title3)
                .foregroundStyle(project.accent)
                .frame(width: 30, height: 30)
                .background(project.accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(project.name)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Text("\(project.signalCount)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.54))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(.white.opacity(0.08), in: Capsule())
                }
                Text(project.recommendedAction)
                    .font(.caption)
                    .foregroundStyle(project.accent)
                    .lineLimit(1)
                Text(project.summary)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.50))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(selected ? Color.white.opacity(0.10) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct ProjectSignalSection<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title, symbol: symbol)
            VStack(spacing: 0) {
                content()
            }
            .darkPanel()
        }
    }
}

struct SourceListRow: View {
    let source: BrainSource
    let selected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: source.symbol)
                .font(.title3)
                .foregroundStyle(source.state.color)
                .frame(width: 28, height: 28)
                .background(source.state.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(source.name)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                Text(source.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(2)
            }
            Spacer()
            Text(source.status)
                .font(.callout.weight(.bold))
                .foregroundStyle(.white.opacity(0.86))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(selected ? Color.white.opacity(0.10) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct BriefingRow: View {
    let item: BriefingItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.symbol)
                .font(.title3)
                .foregroundStyle(.cyan)
                .frame(width: 28, height: 28)
                .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(item.detail)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

struct DailyCommandRow: View {
    let item: DailyCommandItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.symbol)
                .font(.title3)
                .foregroundStyle(item.state.color)
                .frame(width: 30, height: 30)
                .background(item.state.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Text(item.priority)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.state.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.state.color.opacity(0.13), in: Capsule())
                }
                Text(item.project)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)
                Text(item.detail)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

struct RadarItemRow: View {
    let item: RadarItem
    let selected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.symbol)
                .font(.title3)
                .foregroundStyle(item.state.color)
                .frame(width: 30, height: 30)
                .background(item.state.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Text("\(item.score)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.state.color.opacity(0.16), in: Capsule())
                    if item.disposition != .fresh {
                        Text(item.disposition.label)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.58))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.08), in: Capsule())
                    }
                    Text(item.urgency)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.state.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.state.color.opacity(0.13), in: Capsule())
                }
                Text(item.project)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)
                Text(item.detail)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                Text(item.reason)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.44))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(selected ? Color.white.opacity(0.10) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct BlindspotItemRow: View {
    let item: BlindspotItem
    let selected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.symbol)
                .font(.title3)
                .foregroundStyle(item.state.color)
                .frame(width: 30, height: 30)
                .background(item.state.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Text("\(item.score)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.state.color.opacity(0.16), in: Capsule())
                    Text(item.nextAction)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.state.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.state.color.opacity(0.13), in: Capsule())
                }
                Text(item.project)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)
                Text(item.question)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.66))
                    .lineLimit(2)
                Text(item.why)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.44))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(selected ? Color.white.opacity(0.10) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct IdeaPulseRow: View {
    let item: IdeaPulseItem
    let selected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.symbol)
                .font(.title3)
                .foregroundStyle(item.state.color)
                .frame(width: 30, height: 30)
                .background(item.state.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Text("\(item.score)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.state.color.opacity(0.16), in: Capsule())
                }
                Text(item.project)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)
                Text(item.nextPrompt)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.66))
                    .lineLimit(2)
                Text(item.whyNow)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.44))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(selected ? Color.white.opacity(0.10) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct OracleBriefLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkle")
                .font(.caption.weight(.bold))
                .foregroundStyle(.cyan)
                .frame(width: 20, height: 20)
                .background(.cyan.opacity(0.12), in: Circle())
            Text(text)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.74))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

struct OperatorDeckCard: View {
    let kicker: String
    let title: String
    let detail: String
    let symbol: String
    let accent: Color
    let primaryTitle: String
    let primarySymbol: String
    let secondaryTitle: String?
    let secondarySymbol: String?
    let secondaryAction: (() -> Void)?
    let action: () -> Void

    init(
        kicker: String,
        title: String,
        detail: String,
        symbol: String,
        accent: Color,
        primaryTitle: String,
        primarySymbol: String,
        secondaryTitle: String? = nil,
        secondarySymbol: String? = nil,
        secondaryAction: (() -> Void)? = nil,
        action: @escaping () -> Void
    ) {
        self.kicker = kicker
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.accent = accent
        self.primaryTitle = primaryTitle
        self.primarySymbol = primarySymbol
        self.secondaryTitle = secondaryTitle
        self.secondarySymbol = secondarySymbol
        self.secondaryAction = secondaryAction
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: symbol)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(accent)
                    .frame(width: 34, height: 34)
                    .background(accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(kicker)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(accent)
                        .textCase(.uppercase)
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }
            }

            Text(detail)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button(action: action) {
                    Label(primaryTitle, systemImage: primarySymbol)
                        .font(.callout.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(accent)

                if let secondaryAction, let secondaryTitle, let secondarySymbol {
                    Button(action: secondaryAction) {
                        Label(secondaryTitle, systemImage: secondarySymbol)
                            .font(.callout.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .tint(accent)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 196, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [.white.opacity(0.10), accent.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

struct ValueBriefTile: View {
    let label: String
    let title: String
    let detail: String
    let action: String
    let symbol: String
    let accent: Color
    let onAction: () -> Void

    var body: some View {
        Button(action: onAction) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: symbol)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(accent)
                        .frame(width: 32, height: 32)
                        .background(accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(label)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accent)
                            .textCase(.uppercase)
                        Text(title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                    }
                    Spacer()
                }

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.60))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Label(action, systemImage: "arrow.right.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accent)
                    .lineLimit(1)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 176, alignment: .topLeading)
            .background(
                LinearGradient(
                    colors: [.white.opacity(0.09), accent.opacity(0.07)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct OracleCard<Actions: View>: View {
    let item: OracleItem
    let accent: Color
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.symbol)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        Text("\(item.kind.label) - \(item.source)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(color)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(item.confidence)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.52))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.07), in: Capsule())
                }

                Text(item.detail)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(3)

                actions()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }

    private var color: Color {
        switch item.kind {
        case .bubbling: return accent
        case .idea: return .cyan
        case .openLoop: return .orange
        case .decision: return .green
        case .opportunity: return .mint
        }
    }
}

struct EmptyStateRow: View {
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.46))
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.76))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.48))
            }
            Spacer()
        }
        .padding(12)
    }
}

struct SourceInfoPill: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.44))
                    .textCase(.uppercase)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.80))
                    .lineLimit(1)
            }
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(.white.opacity(0.60))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

struct SourceMetricTile: View {
    let metric: SourceMetric
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: metric.symbol)
                    .foregroundStyle(accent)
                Spacer()
            }
            Text(metric.value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
            Text(metric.label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.76))
            Text(metric.detail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.44))
                .lineLimit(2)
        }
        .padding(11)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.08), lineWidth: 1))
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(.white.opacity(0.62))
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.78))
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.44))
        }
        .padding(12)
        .frame(width: 102, height: 112, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct PolicyLine: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.callout)
            .foregroundStyle(.white.opacity(0.72))
    }
}

struct TerminalOutput: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title, symbol: "terminal")
            ScrollView(.horizontal) {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.green.opacity(0.82))
                    .textSelection(.enabled)
                    .padding(12)
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .background(.black.opacity(0.46), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct StatusPill: View {
    let text: String
    let state: HealthState

    var body: some View {
        Label(text, systemImage: state == .good ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
            .font(.caption.weight(.bold))
            .foregroundStyle(state.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.white.opacity(0.08), in: Capsule())
    }
}

struct SystemSurfaceCard: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(.cyan)
                    .frame(width: 28)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.54))
                .lineLimit(4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .darkPanel()
    }
}

private extension Text {
    func sidebarHeader() -> some View {
        self
            .font(.caption.weight(.bold))
            .foregroundStyle(.white.opacity(0.42))
            .textCase(.uppercase)
            .padding(.horizontal, 12)
    }
}

private extension View {
    func darkPanel() -> some View {
        self
            .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))
            .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 10)
    }
}
