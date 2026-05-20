import AppIntents
import AppKit
import Foundation

enum ShortcutClient {
    static let api = URL(string: "http://127.0.0.1:8765")!

    static func text(path: String) async throws -> String {
        guard let url = URL(string: path, relativeTo: api)?.absoluteURL else {
            throw ShortcutError.invalidURL
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 200 else {
                throw ShortcutError.requestFailed(status: status)
            }
            guard let text = String(data: data, encoding: .utf8), !text.isEmpty else {
                throw ShortcutError.emptyResponse
            }
            return text
        } catch let error as ShortcutError {
            throw error
        } catch {
            throw ShortcutError.unreachable(error.localizedDescription)
        }
    }

    static func json(path: String) async throws -> [String: Any] {
        guard let url = URL(string: path, relativeTo: api)?.absoluteURL else {
            throw ShortcutError.invalidURL
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 200 else {
                throw ShortcutError.requestFailed(status: status)
            }
            guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw ShortcutError.emptyResponse
            }
            return payload
        } catch let error as ShortcutError {
            throw error
        } catch {
            throw ShortcutError.unreachable(error.localizedDescription)
        }
    }

    static func post(path: String, body: [String: Any]) async throws {
        guard let url = URL(string: path, relativeTo: api)?.absoluteURL else {
            throw ShortcutError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 200 else {
                throw ShortcutError.requestFailed(status: status)
            }
        } catch let error as ShortcutError {
            throw error
        } catch {
            throw ShortcutError.unreachable(error.localizedDescription)
        }
    }
}

enum ShortcutError: LocalizedError {
    case invalidURL
    case unreachable(String)
    case requestFailed(status: Int)
    case emptyResponse
    case emptyQuery
    case noContextPack

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Terminal Brain shortcut URL is invalid."
        case .unreachable(let detail):
            return "Terminal Brain is not reachable at 127.0.0.1:8765. Open the app, then try again. \(detail)"
        case .requestFailed(let status):
            return "Terminal Brain returned HTTP \(status)."
        case .emptyResponse:
            return "Terminal Brain returned an empty response."
        case .emptyQuery:
            return "Enter a project, task, repo, or question before building a context pack."
        case .noContextPack:
            return "No Terminal Brain context pack exists yet. Build one with Start Work, then try again."
        }
    }
}

struct CopyOperatorDeckIntent: AppIntent {
    static var title: LocalizedStringResource = "Copy Operator Deck"
    static var description = IntentDescription("Copy Terminal Brain's four-card Operator Deck as Markdown.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let markdown = try await ShortcutClient.text(path: "/operator-deck/markdown")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
        return .result(dialog: "Operator Deck copied.")
    }
}

struct CopyOperatorSnapshotIntent: AppIntent {
    static var title: LocalizedStringResource = "Copy Operator Snapshot"
    static var description = IntentDescription("Copy Terminal Brain's full operator snapshot as Markdown.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let markdown = try await ShortcutClient.text(path: "/snapshot/markdown")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
        return .result(dialog: "Operator Snapshot copied.")
    }
}

struct CopyOperatorBriefIntent: AppIntent {
    static var title: LocalizedStringResource = "Copy Operator Brief"
    static var description = IntentDescription("Copy Terminal Brain's plain-language Operator Brief as Markdown.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let markdown = try await ShortcutClient.text(path: "/operator-brief/markdown")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
        return .result(dialog: "Operator Brief copied.")
    }
}

struct CopyDecisionLaneIntent: AppIntent {
    static var title: LocalizedStringResource = "Copy Decision Lane"
    static var description = IntentDescription("Copy Terminal Brain's ranked Decision Lane as Markdown.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let markdown = try await ShortcutClient.text(path: "/today/markdown")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
        return .result(dialog: "Decision Lane copied.")
    }
}

struct RunTerminalBrainSyncIntent: AppIntent {
    static var title: LocalizedStringResource = "Run Terminal Brain Sync"
    static var description = IntentDescription("Run Terminal Brain sync with Apple Notes excluded by default.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await ShortcutClient.post(path: "/sync", body: ["includeAppleNotes": false])
        return .result(dialog: "Terminal Brain sync started.")
    }
}

struct BuildContextPackIntent: AppIntent {
    static var title: LocalizedStringResource = "Build Context Pack"
    static var description = IntentDescription("Build a Terminal Brain context pack for a project, task, repo, or question.")

    @Parameter(title: "Work Query", description: "Project, task, repo, or question.")
    var query: String

    static var parameterSummary: some ParameterSummary {
        Summary("Build context pack for \(\.$query)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ShortcutError.emptyQuery
        }
        try await ShortcutClient.post(path: "/start-work", body: ["query": trimmed])
        return .result(dialog: "Context pack built.")
    }
}

struct OpenLatestContextPackIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Latest Context Pack"
    static var description = IntentDescription("Open the newest Terminal Brain context pack.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let payload = try await ShortcutClient.json(path: "/context-packs/latest")
        guard payload["ok"] as? Bool == true,
              let path = payload["path"] as? String,
              !path.isEmpty else {
            throw ShortcutError.noContextPack
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
        return .result(dialog: "Latest context pack opened.")
    }
}

struct CopyLatestContextPackIntent: AppIntent {
    static var title: LocalizedStringResource = "Copy Latest Context Pack"
    static var description = IntentDescription("Copy the newest Terminal Brain context pack as Markdown.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let payload = try await ShortcutClient.json(path: "/context-packs/latest")
        guard payload["ok"] as? Bool == true else {
            throw ShortcutError.noContextPack
        }
        let markdown = try await ShortcutClient.text(path: "/context-packs/latest/markdown")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
        return .result(dialog: "Latest context pack copied.")
    }
}

struct CopyAgentHandoffIntent: AppIntent {
    static var title: LocalizedStringResource = "Copy Agent Handoff"
    static var description = IntentDescription("Copy the Terminal Brain Operator Brief, Decision Lane, Operator Deck, and latest context pack as one Markdown handoff.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let markdown = try await ShortcutClient.text(path: "/handoff/markdown")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
        return .result(dialog: "Agent handoff copied.")
    }
}

struct TerminalBrainShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CopyOperatorDeckIntent(),
            phrases: [
                "Copy \(.applicationName) deck",
                "Copy \(.applicationName) operator deck"
            ],
            shortTitle: "Copy Deck",
            systemImageName: "rectangle.stack"
        )
        AppShortcut(
            intent: CopyOperatorSnapshotIntent(),
            phrases: [
                "Copy \(.applicationName) snapshot",
                "Copy \(.applicationName) operator snapshot"
            ],
            shortTitle: "Copy Snapshot",
            systemImageName: "doc.on.clipboard"
        )
        AppShortcut(
            intent: CopyOperatorBriefIntent(),
            phrases: [
                "Copy \(.applicationName) brief",
                "Copy \(.applicationName) operator brief"
            ],
            shortTitle: "Copy Brief",
            systemImageName: "wand.and.stars"
        )
        AppShortcut(
            intent: CopyDecisionLaneIntent(),
            phrases: [
                "Copy \(.applicationName) decision lane",
                "Copy \(.applicationName) today"
            ],
            shortTitle: "Copy Decisions",
            systemImageName: "list.number"
        )
        AppShortcut(
            intent: RunTerminalBrainSyncIntent(),
            phrases: [
                "Run \(.applicationName) sync",
                "Sync \(.applicationName)"
            ],
            shortTitle: "Run Sync",
            systemImageName: "arrow.triangle.2.circlepath"
        )
        AppShortcut(
            intent: BuildContextPackIntent(),
            phrases: [
                "Start work with \(.applicationName)",
                "Build context pack with \(.applicationName)"
            ],
            shortTitle: "Start Work",
            systemImageName: "shippingbox"
        )
        AppShortcut(
            intent: OpenLatestContextPackIntent(),
            phrases: [
                "Open latest \(.applicationName) context pack",
                "Open \(.applicationName) latest pack"
            ],
            shortTitle: "Open Pack",
            systemImageName: "doc.richtext"
        )
        AppShortcut(
            intent: CopyLatestContextPackIntent(),
            phrases: [
                "Copy latest \(.applicationName) context pack",
                "Copy \(.applicationName) latest pack"
            ],
            shortTitle: "Copy Pack",
            systemImageName: "doc.on.doc"
        )
        AppShortcut(
            intent: CopyAgentHandoffIntent(),
            phrases: [
                "Copy \(.applicationName) handoff",
                "Copy \(.applicationName) agent handoff"
            ],
            shortTitle: "Copy Handoff",
            systemImageName: "doc.richtext"
        )
    }
}
