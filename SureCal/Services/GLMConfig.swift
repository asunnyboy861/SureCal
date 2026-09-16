import Foundation

enum GLMConfig {
    static let endpoint = URL(string: "https://open.bigmodel.cn/api/paas/v4/chat/completions")!
    static let model = "glm-5.3-flash"
    static let timeout: TimeInterval = 90

    static var apiKey: String {
        guard let url = Bundle.main.url(forResource: "GLMSecret", withExtension: "txt") else { return "" }
        return ((try? String(contentsOf: url, encoding: .utf8)) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var isConfigured: Bool { !apiKey.isEmpty }
}
