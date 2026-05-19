import Foundation

enum CommandRunner {
    static func run(_ executable: String, _ arguments: [String] = [], environment: [String: String] = [:]) async -> CommandResult {
        await Task.detached(priority: .utility) {
            let process = Process()
            let stdout = Pipe()
            let stderr = Pipe()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = stdout
            process.standardError = stderr

            if !environment.isEmpty {
                var env = ProcessInfo.processInfo.environment
                for (key, value) in environment {
                    env[key] = value
                }
                process.environment = env
            }

            do {
                try process.run()
                process.waitUntilExit()
                let output = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let error = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                return CommandResult(stdout: output, stderr: error, status: process.terminationStatus)
            } catch {
                return CommandResult(stdout: "", stderr: error.localizedDescription, status: 127)
            }
        }.value
    }

    static func readText(_ path: String) -> String {
        (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
    }

    static func readJSON(_ path: String) -> [String: Any] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dict = object as? [String: Any] else {
            return [:]
        }
        return dict
    }
}
