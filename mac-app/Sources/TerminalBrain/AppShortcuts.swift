import AppIntents
import AppKit
import Foundation

enum ShortcutClient {
    static let api = URL(string: "http://127.0.0.1:8765")!

    static func text(path: String) async throws -> String {
        guard let url = URL(string: path, relativeTo: api)?.absoluteURL else {
            throw ShortcutError.requestFailed
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let text = String(data: data, encoding: .utf8),
              !text.isEmpty else {
            throw ShortcutError.requestFailed
        }
        return text
    }

    static func post(path: String, body: [String: Any]) async throws {
        guard let url = URL(string: path, relativeTo: api)?.absoluteURL else {
            throw ShortcutError.requestFailed
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw ShortcutError.requestFailed
        }
    }
}

enum ShortcutError: Error {
    case requestFailed
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

struct RunTerminalBrainSyncIntent: AppIntent {
    static var title: LocalizedStringResource = "Run Terminal Brain Sync"
    static var description = IntentDescription("Run Terminal Brain sync with Apple Notes excluded by default.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await ShortcutClient.post(path: "/sync", body: ["includeAppleNotes": false])
        return .result(dialog: "Terminal Brain sync started.")
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
            intent: RunTerminalBrainSyncIntent(),
            phrases: [
                "Run \(.applicationName) sync",
                "Sync \(.applicationName)"
            ],
            shortTitle: "Run Sync",
            systemImageName: "arrow.triangle.2.circlepath"
        )
    }
}
