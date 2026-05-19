import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: BrainStatusModel
    @EnvironmentObject private var settings: AppSettings
    @State private var selectedSection = "cockpit"
    @State private var selectedFeedID = ""
    @State private var selectedCommitID = ""
    @State private var feedFilter: FeedKind = .all
    @State private var selectedSourceID = "obsidian"
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
        model.oracleCommits.first { $0.id == selectedCommitID } ?? model.oracleCommits.first
    }

    private var commandItems: [BrainCommand] {
        var items: [BrainCommand] = [
            BrainCommand(title: "Open Cockpit", subtitle: "Local gateway, source health, and Mission reachability", symbol: "house.fill", category: "Navigate", action: .section("cockpit")),
            BrainCommand(title: "Open Feed", subtitle: "Recent context packs, sync events, and source alerts", symbol: "list.bullet.rectangle.portrait.fill", category: "Navigate", action: .section("feed")),
            BrainCommand(title: "Open Oracle", subtitle: "Narrative brief, bubbling ideas, and open loops", symbol: "sparkle.magnifyingglass", category: "Navigate", action: .section("oracle")),
            BrainCommand(title: "Open Review Queue", subtitle: "Committed Oracle reads, decisions, and follow-ups", symbol: "tray.and.arrow.down.fill", category: "Navigate", action: .section("review")),
            BrainCommand(title: "Open Today", subtitle: "Deterministic daily briefing", symbol: "sun.max.fill", category: "Navigate", action: .section("briefing")),
            BrainCommand(title: "Open Sources", subtitle: "Permissioned capture, memory, and compute surfaces", symbol: "tray.full.fill", category: "Navigate", action: .section("sources")),
            BrainCommand(title: "Open System", subtitle: "Native macOS surfaces and integration roadmap", symbol: "puzzlepiece.extension.fill", category: "Navigate", action: .section("system")),
            BrainCommand(title: "Run Sync", subtitle: "Refresh edge brain export with current permission policy", symbol: "arrow.triangle.2.circlepath", category: "Action", action: .runSync),
            BrainCommand(title: "Open Mission Control", subtitle: Paths.missionURL.absoluteString, symbol: "display", category: "Action", action: .openMission),
            BrainCommand(title: "Open Logs", subtitle: Paths.syncLog, symbol: "doc.text", category: "Action", action: .openLogs),
            BrainCommand(title: "Open Workspace", subtitle: Paths.workspace, symbol: "folder", category: "Action", action: .openWorkspace)
        ]

        let contextQuery = inferredContextQuery()
        if !contextQuery.isEmpty {
            items.insert(
                BrainCommand(
                    title: "Build context pack",
                    subtitle: contextQuery,
                    symbol: "shippingbox.fill",
                    category: "Start Work",
                    action: .buildContext(contextQuery)
                ),
                at: 0
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
        case "feed": return "Feed"
        case "oracle": return "Oracle"
        case "review": return "Review"
        case "sources": return "Sources"
        case "briefing": return "Today"
        case "start": return "Start Work"
        case "system": return "System"
        default: return "Cockpit"
        }
    }

    private var sectionSubtitle: String {
        switch selectedSection {
        case "feed": return "Recent context packs, sync events, and source alerts."
        case "oracle": return "Narrative signals, open loops, and ideas worth revisiting."
        case "review": return "Committed Oracle reads that need acceptance, linking, delegation, or dismissal."
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
                NavRow(title: "Cockpit", symbol: "house.fill", badge: model.summaryLine == "Brain status ready" ? "" : "!", selected: selectedSection == "cockpit") { selectedSection = "cockpit" }
                NavRow(title: "Oracle", symbol: "sparkle.magnifyingglass", badge: "\(model.oracleItems.count)", selected: selectedSection == "oracle") { selectedSection = "oracle" }
                NavRow(title: "Review", symbol: "tray.and.arrow.down.fill", badge: "\(model.oracleCommits.filter { $0.status == .new }.count)", selected: selectedSection == "review") { selectedSection = "review" }
                NavRow(title: "Feed", symbol: "list.bullet.rectangle.portrait.fill", badge: "\(model.feedItems.count)", selected: selectedSection == "feed") { selectedSection = "feed" }
                NavRow(title: "Today", symbol: "sun.max.fill", badge: "\(model.briefing.count)", selected: selectedSection == "briefing") { selectedSection = "briefing" }
                NavRow(title: "Start Work", symbol: "sparkles", badge: "", selected: selectedSection == "start") { selectedSection = "start" }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Library")
                    .sidebarHeader()
                NavRow(title: "Sources", symbol: "tray.full.fill", badge: "\(model.sources.count)", selected: selectedSection == "sources") { selectedSection = "sources" }
                NavRow(title: "System", symbol: "puzzlepiece.extension.fill", badge: "6", selected: selectedSection == "system") { selectedSection = "system" }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 9) {
                MiniStatus(label: "API", value: "8765", symbol: "network")
                MiniStatus(label: "MCP", value: "Gateway", symbol: "antenna.radiowaves.left.and.right")
                MiniStatus(label: "Safety", value: "Prompt safe", symbol: "lock.shield.fill")
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

    private var profileMenu: some View {
        Menu {
            Section("Profile") {
                Label("Jonathan Christensen", systemImage: "person.crop.circle")
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
                Label("Jonathan Christensen", systemImage: "person.crop.circle")
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
                    case "oracle": oracleView
                    case "review": reviewView
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

    private var heroPanel: some View {
        HStack(alignment: .bottom, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Brain gateway")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(settings.theme.accent)
                    .textCase(.uppercase)
                Text("Ready for agent work.")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("Terminal Brain owns the local control plane. Sensitive sources remain explicit, Mission Control is reachable, and agents can use the MCP gateway without waking Apple Notes or Drafts bridges.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.64))
                    .frame(maxWidth: 740, alignment: .leading)
            }
            Spacer()
            MetricTile(title: "Mission", value: "10028", detail: "points", symbol: "display")
            MetricTile(title: "Sync", value: "4231", detail: "records", symbol: "arrow.triangle.2.circlepath")
            MetricTile(title: "Memory", value: "1.62M", detail: "agent records", symbol: "brain")
        }
        .padding(20)
        .background(
            LinearGradient(colors: [.white.opacity(0.12), settings.theme.accent.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
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

                VStack(spacing: 0) {
                    ForEach(model.oracleCommits) { commit in
                        Button {
                            selectedCommitID = commit.id
                        } label: {
                            OracleCommitRow(commit: commit, selected: selectedOracleCommit?.id == commit.id)
                        }
                        .buttonStyle(.plain)
                        if commit.id != model.oracleCommits.last?.id {
                            Divider().overlay(.white.opacity(0.08)).padding(.leading, 54)
                        }
                    }
                    if model.oracleCommits.isEmpty {
                        EmptyStateRow(
                            title: "No committed reads yet",
                            detail: "Ask Oracle, then use Commit to create reviewable memory.",
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
                                Text("\(commit.source) - \(commit.created.formatted(date: .abbreviated, time: .shortened))")
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

                        Text(commit.path)
                            .font(.caption.monospaced())
                            .foregroundStyle(.white.opacity(0.44))
                            .lineLimit(2)
                            .textSelection(.enabled)

                        HStack {
                            Button { model.openPath(commit.path) } label: { Label("Open", systemImage: "arrow.up.right.square") }
                            Button { model.setOracleCommitStatus(commit, status: .accepted) } label: { Label("Accept", systemImage: "checkmark.seal") }
                            Button { model.setOracleCommitStatus(commit, status: .linked) } label: { Label("Linked", systemImage: "link") }
                            Button { model.setOracleCommitStatus(commit, status: .delegated) } label: { Label("Delegate", systemImage: "paperplane") }
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
                SectionTitle("Briefing", symbol: "sun.max.fill")
                VStack(spacing: 0) {
                    ForEach(model.briefing) { item in
                        BriefingRow(item: item)
                        if item.id != model.briefing.last?.id {
                            Divider().overlay(.white.opacity(0.08)).padding(.leading, 48)
                        }
                    }
                }
                .darkPanel()
            }
            .frame(minWidth: 620)
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Next Actions", symbol: "sparkles")
                VStack(alignment: .leading, spacing: 10) {
                    PolicyLine("Build a Start Work pack before major agent sessions.")
                    PolicyLine("Review source policy before enabling Apple Notes sync.")
                    PolicyLine("Move Terminal Brain to /Applications after signing is stable.")
                }
                .padding(16)
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
            SystemSurfaceCard(title: "Shortcuts", value: "Next", detail: "Expose Run Sync and Start Work as App Shortcuts for Spotlight/Siri/automation.", symbol: "wand.and.stars")
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
        case .buildContext(let query):
            model.workQuery = query
            selectedSection = "start"
            Task { await model.startWork() }
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
    case openMission
    case openLogs
    case openWorkspace
    case openPath(String)
    case runSync
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
