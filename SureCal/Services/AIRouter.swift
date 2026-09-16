import Foundation

struct UnconfiguredEngine: VisionNutritionEngine {
    let engineID = "unconfigured"
    var errorDescription: String {
        "AI engine is not configured on this build. Add your own API key in Settings - AI Engine to enable photo scanning."
    }

    func analyze(imageData: Data, context: MealContext) async throws -> FoodAnalysis {
        throw VisionEngineError.badResponse
    }
}

enum AIRouter {
    static func primaryEngine() -> VisionNutritionEngine {
        if let key = KeychainHelper.readString(service: "SureCal", account: "byo_api_key"), !key.isEmpty {
            let endpointString = KeychainHelper.readString(service: "SureCal", account: "byo_endpoint") ?? "https://open.bigmodel.cn/api/paas/v4/chat/completions"
            let model = KeychainHelper.readString(service: "SureCal", account: "byo_model") ?? GLMConfig.model
            let endpoint = URL(string: endpointString) ?? GLMConfig.endpoint
            return BYOVisionEngine(apiKey: key, endpoint: endpoint, model: model)
        }
        if GLMConfig.isConfigured {
            return GLMFlashVisionEngine()
        }
        return UnconfiguredEngine()
    }

    static func verifyEngine() -> VisionNutritionEngine {
        return GLMFlashVisionEngine()
    }

    static func isHardCase(_ analysis: FoodAnalysis) -> Bool {
        analysis.isMixedDish || analysis.overallConfidence < 0.85 ||
        analysis.items.contains { $0.confidence < 0.7 }
    }
}
