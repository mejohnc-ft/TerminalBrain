import Foundation
import Network

final class LocalControlServer {
    private let port: NWEndpoint.Port = 8765
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.franklin.terminal-brain.control-api")

    func start() {
        guard listener == nil else { return }
        do {
            let listener = try NWListener(using: .tcp, on: port)
            listener.newConnectionHandler = { [weak self] connection in
                self?.handle(connection)
            }
            listener.start(queue: queue)
            self.listener = listener
        } catch {
            fputs("Terminal Brain control API failed to start: \(error)\n", stderr)
        }
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(connection, Data())
    }

    private func receive(_ connection: NWConnection, _ buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            var next = buffer
            if let data {
                next.append(data)
            }
            if let request = HTTPRequest.parse(next) {
                Task {
                    let response = await self.route(request)
                    self.send(response, on: connection)
                }
                return
            }
            if isComplete || error != nil {
                self.send(.json(400, ["error": "Invalid or incomplete HTTP request"]), on: connection)
                return
            }
            self.receive(connection, next)
        }
    }

    private func send(_ response: HTTPResponse, on connection: NWConnection) {
        connection.send(content: response.data, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private func route(_ request: HTTPRequest) async -> HTTPResponse {
        switch (request.method, request.path) {
        case ("GET", "/health"):
            return .json(200, ["ok": true, "service": "terminal-brain", "port": 8765])
        case ("GET", "/status"):
            return .json(200, await ControlSnapshot.status())
        case ("GET", "/sources"):
            return .json(200, await ControlSnapshot.sources())
        case ("GET", "/projects"):
            return .json(200, ProjectSnapshot.projects())
        case ("GET", "/briefing"):
            return .json(200, await ControlSnapshot.briefing())
        case ("GET", "/permissions"):
            return .json(200, ControlSnapshot.permissions())
        case ("GET", "/oracle/brief"):
            return .json(200, await OracleSnapshot.brief())
        case ("GET", "/oracle/items"):
            return .json(200, await OracleSnapshot.items())
        case ("GET", "/oracle/commits"):
            return .json(200, OracleSnapshot.commits())
        case ("POST", "/oracle/ask"):
            let question = (request.jsonBody?["question"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !question.isEmpty else {
                return .json(400, ["ok": false, "error": "question is required"])
            }
            return .json(200, await OracleSnapshot.ask(question: question))
        case ("POST", "/oracle/commit"):
            let title = (request.jsonBody?["title"] as? String ?? "Oracle Read").trimmingCharacters(in: .whitespacesAndNewlines)
            let content = (request.jsonBody?["content"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty else {
                return .json(400, ["ok": false, "error": "content is required"])
            }
            return .json(200, OracleSnapshot.commit(
                title: title.isEmpty ? "Oracle Read" : title,
                content: content,
                question: request.jsonBody?["question"] as? String ?? "",
                source: request.jsonBody?["source"] as? String ?? "Terminal Brain Oracle",
                project: request.jsonBody?["project"] as? String ?? "",
                tags: request.jsonBody?["tags"] as? [String] ?? []
            ))
        case ("POST", "/sync"):
            let includeNotes = request.jsonBody?["includeAppleNotes"] as? Bool ?? false
            let result = await CommandRunner.run(
                "/bin/zsh",
                [Paths.syncScript],
                environment: ["EDGE_BRAIN_INCLUDE_APPLE_NOTES": includeNotes ? "1" : "0"]
            )
            return .json(200, [
                "ok": result.succeeded,
                "status": result.status,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "includeAppleNotes": includeNotes
            ])
        case ("POST", "/start-work"):
            let query = (request.jsonBody?["query"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else {
                return .json(400, ["ok": false, "error": "query is required"])
            }
            let result = await CommandRunner.run("/usr/bin/env", ["node", Paths.brainCLI, "context-pack-save", query, Paths.workspace])
            return .json(200, [
                "ok": result.succeeded,
                "query": query,
                "status": result.status,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "latestContextPack": ControlSnapshot.newestContextPackPath()
            ])
        default:
            return .json(404, ["error": "Unknown route", "path": request.path])
        }
    }
}

enum OracleSnapshot {
    static func brief() async -> [String: Any] {
        let status = await ControlSnapshot.status()
        let items = oracleItems()
        return [
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "mode": "deterministic-local",
            "brief": briefLines(status: status, items: items)
        ]
    }

    static func items() async -> [String: Any] {
        [
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "mode": "deterministic-local",
            "items": oracleItems()
        ]
    }

    static func ask(question: String) async -> [String: Any] {
        let status = await ControlSnapshot.status()
        let items = oracleItems()
        let retrieval = await missionSearch(question: question)
        let localAnswer = answer(question: question, status: status, items: items)
        let synthesis = await missionSynthesis(
            question: question,
            status: status,
            items: Array(items.prefix(8)),
            retrieval: retrieval,
            localAnswer: localAnswer
        )
        let answerText: String
        let mode: String
        if let synthesis, !synthesis.isEmpty {
            answerText = synthesis
            mode = "mission-synthesis"
        } else if !retrieval.isEmpty {
            answerText = retrievalAnswer(question: question, localAnswer: localAnswer, retrieval: retrieval)
            mode = "mission-retrieval"
        } else {
            answerText = localAnswer
            mode = "deterministic-local"
        }
        return [
            "ok": true,
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "mode": mode,
            "question": question,
            "answer": answerText,
            "supportingItems": Array(items.prefix(5)),
            "citations": citations(from: retrieval),
            "retrieval": retrieval,
            "suggestedActions": [
                "Build a context pack for the strongest surfaced item",
                "Commit useful Oracle answers into Obsidian",
                "Run sync after durable notes change",
                "Use Mission Control for heavier synthesis"
            ]
        ]
    }

    static func commit(title: String, content: String, question: String, source: String, project: String, tags: [String]) -> [String: Any] {
        let directory = URL(fileURLWithPath: Paths.workspace).appendingPathComponent("Oracle Inbox", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let fileSafeTimestamp = timestamp.replacingOccurrences(of: ":", with: "-")
            let safeTitle = slug(from: title)
            let fileURL = directory.appendingPathComponent("\(fileSafeTimestamp)-\(safeTitle.isEmpty ? "oracle-read" : safeTitle).md")
            var mergedTags = ["terminal-brain", "oracle"]
            mergedTags.append(contentsOf: tags.map { slug(from: $0) }.filter { !$0.isEmpty })
            mergedTags = Array(Set(mergedTags)).sorted()
            let tagLines = mergedTags.map { "  - \($0)" }.joined(separator: "\n")
            let questionBlock = question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "\n## Question\n\n\(question.trimmingCharacters(in: .whitespacesAndNewlines))\n"
            let resolvedProject = project.trimmingCharacters(in: .whitespacesAndNewlines).ifEmpty(ProjectSnapshot.projectName(from: "\(title) \(question) \(content) \(tags.joined(separator: " "))"))
            let body = """
            ---
            type: oracle_commit
            source: \(source)
            project: \(resolvedProject)
            created: \(timestamp)
            reviewStatus: new
            tags:
            \(tagLines)
            ---

            # \(title)
            \(questionBlock)
            ## Read

            \(content)

            ## Follow Up

            - [ ] Review and link this note to the relevant project or daily note.
            - [ ] Run Terminal Brain sync after edits are final.
            """
            try body.write(to: fileURL, atomically: true, encoding: .utf8)
            return [
                "ok": true,
                "path": fileURL.path,
                "title": title,
                "project": resolvedProject,
                "tags": mergedTags,
                "created": timestamp
            ]
        } catch {
            return [
                "ok": false,
                "error": error.localizedDescription
            ]
        }
    }

    static func commits() -> [String: Any] {
        try? FileManager.default.createDirectory(atPath: Paths.oracleInbox, withIntermediateDirectories: true)
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: Paths.oracleInbox),
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return ["items": []]
        }

        let items: [[String: Any]] = urls
            .filter { $0.pathExtension.lowercased() == "md" }
            .compactMap { url -> (Date, [String: Any])? in
                guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
                let parsed = parseCommit(text)
                let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let created = parsed.created.flatMap { ISO8601DateFormatter().date(from: $0) } ?? modified
                return (
                    created,
                    [
                        "id": url.path,
                        "title": parsed.title.isEmpty ? url.deletingPathExtension().lastPathComponent : parsed.title,
                        "question": parsed.question,
                        "preview": parsed.preview,
                        "status": parsed.frontmatter["reviewStatus"] ?? parsed.frontmatter["status"] ?? "new",
                        "project": (parsed.frontmatter["project"] ?? "").ifEmpty(ProjectSnapshot.projectName(from: "\(parsed.title) \(parsed.question) \(parsed.preview) \(parsed.tags.joined(separator: " "))")),
                        "source": parsed.frontmatter["source"] ?? "Oracle Inbox",
                        "created": ISO8601DateFormatter().string(from: created),
                        "path": url.path,
                        "tags": parsed.tags
                    ]
                )
            }
            .sorted { $0.0 > $1.0 }
            .map { $0.1 }

        return [
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "items": items
        ]
    }

    private static func oracleItems() -> [[String: Any]] {
        var output: [[String: Any]] = [
            [
                "id": "oracle-review-queue",
                "title": "Oracle Review Queue",
                "detail": "Ask and commit now work. The next layer is a review surface that turns committed reads into linked decisions, project notes, and daily priorities.",
                "kind": "opportunity",
                "source": "Current app",
                "confidence": "High",
                "symbol": "tray.and.arrow.down.fill",
                "path": "\(Paths.workspace)/Oracle Inbox"
            ]
        ]
        for pack in recentContextPackDocuments(limit: 8) {
            output.append([
                "id": "context-\(pack.url.lastPathComponent)",
                "title": contextPackTitle(from: pack.url),
                "detail": contextPackPreview(from: pack.text),
                "kind": "opportunity",
                "source": "Context pack",
                "confidence": "High",
                "symbol": "shippingbox.fill",
                "path": pack.url.path
            ])
        }

        let agent = CommandRunner.readJSON(Paths.agentHistoryStatsJSON)
        let records = agent["records"] as? Int ?? 0
        let sessions = agent["sessions"] as? Int ?? 0
        if records > 0 {
            output.append([
                "id": "agent-history",
                "title": "Agent work memory",
                "detail": "\(records) derived Codex/Claude records across \(sessions) sessions are available for continuity.",
                "kind": "bubbling",
                "source": "Agent histories",
                "confidence": "Medium",
                "symbol": "bubble.left.and.text.bubble.right",
                "path": Paths.agentHistoryStatsJSON
            ])
        }

        output.append(contentsOf: extractedItems(limit: 14))
        return dedupe(output).prefix(18).map { $0 }
    }

    private static func briefLines(status: [String: Any], items: [[String: Any]]) -> [String] {
        let indexes = status["indexes"] as? [String: Any] ?? [:]
        let promptSafe = status["promptSafe"] as? Bool ?? false
        let top = items.first?["title"] as? String ?? "no surfaced item yet"
        let openLoop = items.first { ($0["kind"] as? String) == "openLoop" }?["title"] as? String
        return [
            "Durable memory is active: \(indexes["obsidianNotes"] ?? 0) notes, \(indexes["entities"] ?? 0) entities, and \(indexes["agentRecords"] ?? 0) agent-memory records.",
            "The strongest current signal is \(top).",
            promptSafe ? "Permission posture is quiet: prompt-prone Apple Notes and Drafts bridges are not auto-running." : "One or more prompt-prone bridge is active; review source policy before automation.",
            openLoop.map { "The open loop to resolve first is \($0)." } ?? "No urgent open loop was detected in the current local scan."
        ]
    }

    private static func answer(question: String, status: [String: Any], items: [[String: Any]]) -> String {
        let query = question.lowercased()
        let openLoop = items.first { ($0["kind"] as? String) == "openLoop" }?["title"] as? String
        let idea = items.first { ["idea", "opportunity"].contains($0["kind"] as? String ?? "") }?["title"] as? String
        if query.contains("missing") || query.contains("consider") {
            return "What may be missing is \(openLoop ?? "a clearly promoted next action"). The adjacent idea to revisit is \(idea ?? "the latest context pack"). Treat the surfaced cards as review candidates, then promote the useful ones into Obsidian so they become durable memory."
        }
        if query.contains("today") || query.contains("next") || query.contains("work") {
            return "Use \(idea ?? "the freshest context pack") as the working frame. Build a narrow context pack, delegate only the bounded implementation, then write the outcome back into Obsidian."
        }
        if query.contains("safe") || query.contains("permission") || query.contains("prompt") {
            let promptSafe = status["promptSafe"] as? Bool ?? false
            return promptSafe ? "The system is prompt-safe right now: Apple Notes and Drafts bridges are off and the hourly sync agent is unloaded." : "Prompt safety is degraded. Review Apple Notes, Drafts, and LaunchAgent state before enabling automation."
        }
        return items.prefix(4).map {
            let kind = $0["kind"] as? String ?? "signal"
            let title = $0["title"] as? String ?? "Untitled"
            let detail = $0["detail"] as? String ?? ""
            return "\(kind): \(title). \(detail)"
        }.joined(separator: "\n\n")
    }

    private static func missionSearch(question: String) async -> [[String: Any]] {
        async let brain = missionSearchEndpoint(path: "/api/brain/search", label: "Mission Brain", question: question, limit: 3)
        async let edge = missionSearchEndpoint(path: "/api/edge-brain/search", label: "Edge Brain", question: question, limit: 4)
        async let knowledge = missionSearchEndpoint(path: "/api/knowledge/search", label: "Knowledge", question: question, limit: 3)

        let combined = await brain + edge + knowledge
        return dedupe(combined).prefix(8).map { $0 }
    }

    private static func missionSearchEndpoint(path: String, label: String, question: String, limit: Int) async -> [[String: Any]] {
        guard var components = URLComponents(url: Paths.missionURL, resolvingAgainstBaseURL: false) else {
            return []
        }
        components.path = path
        components.queryItems = [URLQueryItem(name: "q", value: question)]
        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["available"] as? Bool != false,
                  let results = json["results"] as? [[String: Any]] else {
                return []
            }
            return results.prefix(limit).map { item in
                normalizedMissionResult(item, endpoint: label)
            }
        } catch {
            return []
        }
    }

    private static func missionSynthesis(
        question: String,
        status: [String: Any],
        items: [[String: Any]],
        retrieval: [[String: Any]],
        localAnswer: String
    ) async -> String? {
        guard !retrieval.isEmpty else { return nil }
        guard var components = URLComponents(url: Paths.missionURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.path = "/api/workbench/chat"
        guard let url = components.url else { return nil }

        let payload: [String: Any] = [
            "provider": "gptoss",
            "model": "qwen3.6-27b",
            "temperature": 0.2,
            "max_tokens": 520,
            "context_bundle": missionContextBundle(
                question: question,
                status: status,
                items: items,
                retrieval: retrieval,
                localAnswer: localAnswer
            ),
            "messages": [
                [
                    "role": "user",
                    "content": """
                    Answer as Terminal Brain's Oracle for John. Be specific, grounded in the supplied context, and concise.
                    Treat the Current Terminal Brain implementation section as authoritative over older retrieved context.

                    Question: \(question)

                    Format:
                    - Direct read
                    - Why this matters
                    - Next 3 moves
                    """
                ]
            ]
        ]

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 90
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("1", forHTTPHeaderField: "X-Mission-Request")
            request.setValue(missionOrigin(), forHTTPHeaderField: "Origin")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let message = json["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                return nil
            }
            let stripped = stripReasoning(content).trimmingCharacters(in: .whitespacesAndNewlines)
            return stripped.isEmpty ? nil : stripped
        } catch {
            return nil
        }
    }

    private static func missionContextBundle(
        question: String,
        status: [String: Any],
        items: [[String: Any]],
        retrieval: [[String: Any]],
        localAnswer: String
    ) -> String {
        let indexes = status["indexes"] as? [String: Any] ?? [:]
        let mission = status["mission"] as? [String: Any] ?? [:]
        let promptSafe = status["promptSafe"] as? Bool ?? false

        var lines: [String] = [
            "Question: \(question)",
            "",
            "System posture:",
            "- Obsidian notes: \(indexes["obsidianNotes"] ?? 0)",
            "- Entities: \(indexes["entities"] ?? 0)",
            "- Agent memory records: \(indexes["agentRecords"] ?? 0)",
            "- Mission points: \(mission["points"] ?? 0)",
            "- Prompt-safe: \(promptSafe ? "yes" : "no")",
            "",
            "Current Terminal Brain implementation:",
            "- Native macOS app with local control API on http://127.0.0.1:8765.",
            "- Current API routes: /health, /status, /sources, /briefing, /permissions, /oracle/brief, /oracle/items, /oracle/ask, /oracle/commit, /sync, /start-work.",
            "- Oracle ask already combines local deterministic signals, Mission retrieval, Mission workbench synthesis, citations, supporting items, and fallback behavior.",
            "- Oracle commit can write synthesized decisions and outcomes into the Obsidian-backed Oracle Inbox.",
            "- MCP proxy can call Terminal Brain status, sources, briefing, permissions, sync, start work, oracle brief, oracle items, oracle ask, and oracle commit.",
            "- Do not describe these implemented capabilities as missing. Recommend what should come after them.",
            "",
            "Local deterministic read:",
            localAnswer.prefixString(maxLength: 1200),
            "",
            "Local Oracle cards:"
        ]

        for item in items.prefix(8) {
            let title = item["title"] as? String ?? "Untitled"
            let kind = item["kind"] as? String ?? "signal"
            let source = item["source"] as? String ?? "local"
            let detail = item["detail"] as? String ?? ""
            lines.append("- [\(kind)] \(title) (\(source)): \(detail.prefixString(maxLength: 420))")
        }

        lines.append("")
        lines.append("Mission retrieval:")
        for result in retrieval.prefix(8) {
            let title = result["title"] as? String ?? "Untitled"
            let source = result["source"] as? String ?? result["endpoint"] as? String ?? "Mission"
            let reference = result["reference"] as? String ?? ""
            let text = result["text"] as? String ?? ""
            lines.append("- \(title) [\(source)] \(reference): \(text.prefixString(maxLength: 700))")
        }

        return lines.joined(separator: "\n").prefixString(maxLength: 9000)
    }

    private static func retrievalAnswer(question: String, localAnswer: String, retrieval: [[String: Any]]) -> String {
        let surfaced = retrieval.prefix(4).map { result in
            let title = result["title"] as? String ?? "Untitled"
            let source = result["source"] as? String ?? result["endpoint"] as? String ?? "Mission"
            let text = result["text"] as? String ?? ""
            return "- \(title) (\(source)): \(text.prefixString(maxLength: 220))"
        }.joined(separator: "\n")

        return """
        \(localAnswer)

        Mission retrieval also surfaced:
        \(surfaced)

        Treat these as grounding references, then ask again when the Mission synthesis lane is available for a more opinionated read.
        """
    }

    private static func normalizedMissionResult(_ item: [String: Any], endpoint: String) -> [String: Any] {
        let title = item["title"] as? String ?? item["record_id"] as? String ?? "Untitled"
        let reference = item["reference"] as? String ?? item["path"] as? String ?? item["source_file"] as? String ?? ""
        let source = item["source_label"] as? String ?? item["source"] as? String ?? endpoint
        let score: Any = item["score"] ?? 0
        let text = item["text"] as? String ?? ""
        return [
            "id": item["record_id"] as? String ?? "\(endpoint)-\(title)-\(reference)",
            "endpoint": endpoint,
            "source": source,
            "title": title.prefixString(maxLength: 140),
            "reference": reference.prefixString(maxLength: 220),
            "score": score,
            "text": text.prefixString(maxLength: 900)
        ]
    }

    private static func citations(from retrieval: [[String: Any]]) -> [[String: Any]] {
        retrieval.prefix(6).map { result in
            [
                "title": result["title"] as? String ?? "Untitled",
                "source": result["source"] as? String ?? result["endpoint"] as? String ?? "Mission",
                "reference": result["reference"] as? String ?? "",
                "score": result["score"] ?? 0
            ]
        }
    }

    private static func missionOrigin() -> String {
        guard let components = URLComponents(url: Paths.missionURL, resolvingAgainstBaseURL: false),
              let scheme = components.scheme,
              let host = components.host else {
            return Paths.missionURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        if let port = components.port {
            return "\(scheme)://\(host):\(port)"
        }
        return "\(scheme)://\(host)"
    }

    private static func stripReasoning(_ text: String) -> String {
        var output = text
        while let start = output.range(of: "<think>", options: .caseInsensitive),
              let end = output.range(of: "</think>", options: .caseInsensitive) {
            output.removeSubrange(start.lowerBound..<end.upperBound)
        }
        return output
    }

    private static func extractedItems(limit: Int) -> [[String: Any]] {
        let markers: [(kind: String, needle: String, symbol: String)] = [
            ("openLoop", "todo", "checklist"),
            ("openLoop", "next", "arrow.right.circle"),
            ("openLoop", "waiting", "hourglass"),
            ("openLoop", "blocked", "exclamationmark.octagon"),
            ("decision", "decision", "checkmark.seal"),
            ("decision", "decided", "checkmark.seal"),
            ("idea", "idea", "lightbulb"),
            ("idea", "maybe", "sparkle.magnifyingglass"),
            ("opportunity", "opportunity", "target"),
            ("bubbling", "should", "bubble.left.and.exclamationmark.bubble.right")
        ]

        var output: [[String: Any]] = []
        for pack in recentContextPackDocuments(limit: 8) {
            let lines = pack.text
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") && !$0.hasPrefix("---") }
            for line in lines {
                let lowered = line.lowercased()
                guard let marker = markers.first(where: { lowered.contains($0.needle) }) else { continue }
                output.append([
                    "id": "line-\(pack.url.lastPathComponent)-\(output.count)",
                    "title": oracleTitle(from: line),
                    "detail": line.prefixString(maxLength: 260),
                    "kind": marker.kind,
                    "source": pack.url.deletingPathExtension().lastPathComponent,
                    "confidence": "Heuristic",
                    "symbol": marker.symbol,
                    "path": pack.url.path
                ])
                if output.count >= limit {
                    return output
                }
            }
        }
        return output
    }

    private static func recentContextPackDocuments(limit: Int) -> [(url: URL, text: String)] {
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

    private static func contextPackTitle(from url: URL) -> String {
        let base = url.deletingPathExtension().lastPathComponent
        let parts = base.split(separator: "-", omittingEmptySubsequences: true)
        let slug = parts.dropFirst(6).joined(separator: " ")
        return slug.isEmpty ? base : slug.capitalized
    }

    private static func contextPackPreview(from text: String) -> String {
        let lines = text
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") && !$0.hasPrefix("---") }
        return lines.prefix(2).joined(separator: " ").prefixString(maxLength: 220)
    }

    private static func oracleTitle(from line: String) -> String {
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

    private static func parseCommit(_ text: String) -> (frontmatter: [String: String], tags: [String], title: String, question: String, preview: String, created: String?) {
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

    private static func sectionText(named section: String, in lines: [String]) -> String {
        guard let start = lines.firstIndex(where: { $0 == "## \(section)" }) else { return "" }
        var output: [String] = []
        for line in lines.dropFirst(start + 1) {
            if line.hasPrefix("## ") { break }
            if !line.isEmpty { output.append(line) }
        }
        return output.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func slug(from text: String) -> String {
        text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .prefix(10)
            .joined(separator: "-")
    }

    private static func dedupe(_ items: [[String: Any]]) -> [[String: Any]] {
        var seen = Set<String>()
        var output: [[String: Any]] = []
        for item in items {
            let key = (item["title"] as? String ?? "").lowercased()
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            output.append(item)
        }
        return output
    }
}

enum ProjectSnapshot {
    static func projects() -> [String: Any] {
        let commits = (OracleSnapshot.commits()["items"] as? [[String: Any]]) ?? []
        let packs = contextPacks(limit: 40)
        var buckets: [String: [String: Any]] = [:]

        func ensure(_ name: String) -> String {
            let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines).ifEmpty("General Brain")
            let id = projectID(from: cleanName)
            if buckets[id] == nil {
                buckets[id] = [
                    "id": id,
                    "name": cleanName,
                    "contextPacks": [],
                    "oracleCommits": [],
                    "openLoops": [],
                    "decisions": []
                ]
            }
            return id
        }

        for pack in packs {
            let name = projectName(from: "\(pack["title"] ?? "") \(pack["detail"] ?? "")")
            let id = ensure(name)
            var existing = buckets[id]?["contextPacks"] as? [[String: Any]] ?? []
            existing.append(pack)
            buckets[id]?["contextPacks"] = existing
        }

        for commit in commits {
            let name = (commit["project"] as? String ?? "").ifEmpty(projectName(from: "\(commit["title"] ?? "") \(commit["question"] ?? "") \(commit["preview"] ?? "") \((commit["tags"] as? [String] ?? []).joined(separator: " "))"))
            let id = ensure(name)
            var existing = buckets[id]?["oracleCommits"] as? [[String: Any]] ?? []
            existing.append(commit)
            buckets[id]?["oracleCommits"] = existing
        }

        var items: [[String: Any]] = []
        for (id, bucket) in buckets {
            let context = bucket["contextPacks"] as? [[String: Any]] ?? []
            let projectCommits = bucket["oracleCommits"] as? [[String: Any]] ?? []
            let name = bucket["name"] as? String ?? "General Brain"
            let signalCount = context.count + projectCommits.count
            let delegated = projectCommits.filter { ($0["status"] as? String) == "delegated" }.count
            let lastActivity = latestDateString(context: context, commits: projectCommits)
            items.append([
                "id": id,
                "name": name,
                "summary": "\(context.count) context pack\(context.count == 1 ? "" : "s") and \(projectCommits.count) committed read\(projectCommits.count == 1 ? "" : "s") are attached to \(name).",
                "recommendedAction": recommendedAction(name: name, commits: projectCommits, context: context),
                "signalCount": signalCount,
                "delegatedCount": delegated,
                "lastActivity": lastActivity,
                "symbol": projectSymbol(for: name),
                "contextPacks": Array(context.prefix(6)),
                "oracleCommits": Array(projectCommits.prefix(8))
            ])
        }

        return [
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "items": items.sorted {
                (($0["signalCount"] as? Int) ?? 0) > (($1["signalCount"] as? Int) ?? 0)
            }
        ]
    }

    private static func contextPacks(limit: Int) -> [[String: Any]] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: Paths.contextPacks),
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return urls
            .filter { $0.pathExtension.lowercased() == "md" }
            .compactMap { url -> (Date, [String: Any])? in
                guard let modified = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else {
                    return nil
                }
                let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
                return (
                    modified,
                    [
                        "id": "context-\(url.lastPathComponent)",
                        "title": contextPackTitle(from: url),
                        "detail": contextPackPreview(from: text),
                        "path": url.path,
                        "modifiedAt": ISO8601DateFormatter().string(from: modified)
                    ]
                )
            }
            .sorted { $0.0 > $1.0 }
            .prefix(limit)
            .map { $0.1 }
    }

    static func projectName(from text: String) -> String {
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

    private static func projectID(from name: String) -> String {
        name.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
            .ifEmpty("general-brain")
    }

    private static func projectSymbol(for name: String) -> String {
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

    private static func recommendedAction(name: String, commits: [[String: Any]], context: [[String: Any]]) -> String {
        if let delegated = commits.first(where: { ($0["status"] as? String) == "delegated" }) {
            return "Turn delegated read into a Start Work pack: \(delegated["title"] as? String ?? name)."
        }
        if let unread = commits.first(where: { ($0["status"] as? String) == "new" }) {
            return "Review and classify the newest Oracle read: \(unread["title"] as? String ?? name)."
        }
        if let fresh = context.first {
            return "Use the freshest context pack as the working frame: \(fresh["title"] as? String ?? name)."
        }
        return "Ask Oracle what changed for \(name), then commit the useful read."
    }

    private static func latestDateString(context: [[String: Any]], commits: [[String: Any]]) -> String {
        let values = context.compactMap { $0["modifiedAt"] as? String } + commits.compactMap { $0["created"] as? String }
        return values.sorted().last ?? ""
    }

    private static func contextPackTitle(from url: URL) -> String {
        let base = url.deletingPathExtension().lastPathComponent
        let parts = base.split(separator: "-", omittingEmptySubsequences: true)
        let slug = parts.dropFirst(6).joined(separator: " ")
        return slug.isEmpty ? base : slug.capitalized
    }

    private static func contextPackPreview(from text: String) -> String {
        let lines = text
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") && !$0.hasPrefix("---") }
        return lines.prefix(2).joined(separator: " ").prefixString(maxLength: 220)
    }
}

struct HTTPRequest {
    let method: String
    let path: String
    let body: Data

    var jsonBody: [String: Any]? {
        guard !body.isEmpty else { return nil }
        return try? JSONSerialization.jsonObject(with: body) as? [String: Any]
    }

    static func parse(_ data: Data) -> HTTPRequest? {
        guard let headerEnd = data.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        let headerData = data[..<headerEnd.lowerBound]
        guard let headerText = String(data: headerData, encoding: .utf8) else { return nil }
        let lines = headerText.components(separatedBy: "\r\n")
        guard let first = lines.first else { return nil }
        let parts = first.split(separator: " ", maxSplits: 2).map(String.init)
        guard parts.count >= 2 else { return nil }

        var contentLength = 0
        for line in lines.dropFirst() {
            let pair = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if pair.count == 2 && pair[0].lowercased() == "content-length" {
                contentLength = Int(pair[1]) ?? 0
            }
        }

        let bodyStart = headerEnd.upperBound
        guard data.count >= bodyStart + contentLength else { return nil }
        let body = Data(data[bodyStart..<(bodyStart + contentLength)])
        let path = parts[1].split(separator: "?", maxSplits: 1).first.map(String.init) ?? parts[1]
        return HTTPRequest(method: parts[0], path: path, body: body)
    }
}

struct HTTPResponse {
    let data: Data

    static func json(_ status: Int, _ body: [String: Any]) -> HTTPResponse {
        let payload = (try? JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted, .sortedKeys])) ?? Data("{}".utf8)
        let reason = status == 200 ? "OK" : status == 400 ? "Bad Request" : "Not Found"
        var header = "HTTP/1.1 \(status) \(reason)\r\n"
        header += "Content-Type: application/json; charset=utf-8\r\n"
        header += "Cache-Control: no-store\r\n"
        header += "Content-Length: \(payload.count)\r\n"
        header += "Connection: close\r\n\r\n"
        var data = Data(header.utf8)
        data.append(payload)
        return HTTPResponse(data: data)
    }
}

enum ControlSnapshot {
    static func status() async -> [String: Any] {
        async let localBrain = pgrep("brain-kernel/server.mjs")
        async let appleNotesMCP = pgrep("apple-notes-mcp/server.mjs")
        async let draftsMCP = pgrep("drafts-obsidian-mcp/server.mjs")
        async let launchd = launchAgentStatus()
        async let mission = missionBrain()

        let stats = CommandRunner.readJSON(Paths.statsJSON)
        let agent = CommandRunner.readJSON(Paths.agentHistoryStatsJSON)
        let sync = CommandRunner.readJSON(Paths.edgeSyncStateJSON)
        let syncRecords = sync["records"] as? [String: Any]
        let localBrainText = await localBrain
        let appleNotesText = await appleNotesMCP
        let draftsText = await draftsMCP
        let launchdText = await launchd
        let missionValue = await mission

        return [
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "app": [
                "name": "Terminal Brain",
                "bundleID": "com.franklin.terminal-brain",
                "controlAPI": "http://127.0.0.1:8765"
            ],
            "mcp": [
                "localBrainRunning": !localBrainText.isEmpty,
                "appleNotesBridgeRunning": !appleNotesText.isEmpty,
                "draftsBridgeRunning": !draftsText.isEmpty
            ],
            "sync": [
                "launchAgentLoaded": !launchdText.contains("Could not find service"),
                "records": sync["exported"] as? Int ?? sync["recordCount"] as? Int ?? syncRecords?.count ?? 0,
                "updatedAt": sync["updatedAt"] as? String ?? "unknown"
            ],
            "indexes": [
                "obsidianNotes": stats["notes"] as? Int ?? 0,
                "entities": stats["entities"] as? Int ?? 0,
                "agentRecords": agent["records"] as? Int ?? 0,
                "agentSessions": agent["sessions"] as? Int ?? 0
            ],
            "mission": missionValue ?? ["reachable": false],
            "promptSafe": appleNotesText.isEmpty && draftsText.isEmpty && launchdText.contains("Could not find service")
        ]
    }

    static func sources() async -> [String: Any] {
        let status = await status()
        let indexes = status["indexes"] as? [String: Any] ?? [:]
        let sync = status["sync"] as? [String: Any] ?? [:]
        let mission = status["mission"] as? [String: Any] ?? [:]
        return [
            "sources": [
                [
                    "id": "obsidian",
                    "name": "Obsidian Vault",
                    "mode": "indexed",
                    "records": indexes["obsidianNotes"] as? Int ?? 0,
                    "sensitive": false
                ],
                [
                    "id": "agent-history",
                    "name": "Codex / Claude Histories",
                    "mode": "derived-memory",
                    "records": indexes["agentRecords"] as? Int ?? 0,
                    "sensitive": true
                ],
                [
                    "id": "drafts",
                    "name": "Drafts",
                    "mode": "manual",
                    "records": sync["records"] as? Int ?? 0,
                    "sensitive": true
                ],
                [
                    "id": "apple-notes",
                    "name": "Apple Notes",
                    "mode": "explicit-only",
                    "records": 0,
                    "sensitive": true
                ],
                [
                    "id": "mission-control",
                    "name": "Mission Control",
                    "mode": (mission["reachable"] as? Bool ?? false) ? "reachable" : "offline",
                    "records": mission["points"] as? Int ?? 0,
                    "sensitive": false
                ]
            ]
        ]
    }

    static func briefing() async -> [String: Any] {
        let status = await status()
        let indexes = status["indexes"] as? [String: Any] ?? [:]
        let sync = status["sync"] as? [String: Any] ?? [:]
        let mission = status["mission"] as? [String: Any] ?? [:]
        return [
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "items": [
                [
                    "title": "Brain Coverage",
                    "detail": "\(indexes["obsidianNotes"] ?? 0) Obsidian notes, \(indexes["entities"] ?? 0) entities, \(indexes["agentRecords"] ?? 0) derived agent-memory records."
                ],
                [
                    "title": "Edge Sync",
                    "detail": "\(sync["records"] ?? 0) records tracked for remote sync. Updated \(sync["updatedAt"] ?? "unknown")."
                ],
                [
                    "title": "Mission Control",
                    "detail": (mission["reachable"] as? Bool ?? false) ? "Remote brain reachable with \(mission["points"] ?? 0) points." : "Remote brain not reachable."
                ],
                [
                    "title": "Prompt Safety",
                    "detail": (status["promptSafe"] as? Bool ?? false) ? "Apple Notes/Drafts bridges and hourly sync are not auto-running." : "One or more prompt-prone bridges is active."
                ]
            ]
        ]
    }

    static func permissions() -> [String: Any] {
        [
            "appleNotes": [
                "startupAccess": false,
                "manualCheckOnly": true,
                "owner": "Terminal Brain.app",
                "bundleID": "com.franklin.terminal-brain"
            ],
            "drafts": [
                "startupAccess": false,
                "manualBridgeOnly": true
            ],
            "obsidian": [
                "vaultPath": Paths.workspace,
                "readDerivedIndex": true
            ]
        ]
    }

    static func newestContextPackPath() -> String {
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

    private static func pgrep(_ pattern: String) async -> String {
        let result = await CommandRunner.run("/usr/bin/pgrep", ["-fl", pattern])
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func launchAgentStatus() async -> String {
        let result = await CommandRunner.run("/bin/launchctl", ["print", "gui/\(getuid())/com.franklin.edge-brain-sync"])
        return [result.stdout, result.stderr].joined(separator: "\n")
    }

    private static func missionBrain() async -> [String: Any]? {
        guard var components = URLComponents(url: Paths.missionURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.path = "/api/brain"
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 4
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let brain = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return [
            "reachable": true,
            "points": brain["total_points"] as? Int ?? brain["points"] as? Int ?? 0
        ]
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
