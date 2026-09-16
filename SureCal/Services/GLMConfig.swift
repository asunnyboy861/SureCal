import Foundation

struct GLMProfile: Sendable, Equatable {
    let apiKey: String
    let endpoint: URL
    let model: String
}

enum GLMConfig {
    static let timeout: TimeInterval = 90

    static var profiles: [GLMProfile] {
        guard let url = Bundle.main.url(forResource: "GLMSecret", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            .compactMap { line in
                let parts = line.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
                guard let key = parts.first, !key.isEmpty else { return nil }
                let endpointString = parts.count > 1 && !parts[1].isEmpty ? parts[1] : "https://open.bigmodel.cn/api/paas/v4/chat/completions"
                let model = parts.count > 2 && !parts[2].isEmpty ? parts[2] : "glm-5.3-flash"
                guard let endpoint = URL(string: endpointString) else { return nil }
                return GLMProfile(apiKey: key, endpoint: endpoint, model: model)
            }
    }

    static var isConfigured: Bool { !profiles.isEmpty }

    static let defaultEndpoint = URL(string: "https://open.bigmodel.cn/api/paas/v4/chat/completions")!
    static let defaultModel = "glm-5.3-flash"
    static let internationalEndpoint = URL(string: "https://api.z.ai/api/paas/v4/chat/completions")!
}
