import Foundation

protocol VisionNutritionEngine: Sendable {
    var engineID: String { get }
    func analyze(imageData: Data, context: MealContext) async throws -> FoodAnalysis
}

enum VisionEngineError: LocalizedError {
    case badResponse
    case http(Int, String)
    case parseFailed
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .badResponse: return "The AI service returned an unexpected response."
        case .http(let code, let body): return "AI service error (\(code)): \(body.prefix(120))"
        case .parseFailed: return "Could not read the analysis result."
        case .notConfigured: return "AI engine is not configured on this build. Add your own API key in Settings - AI Engine to enable photo scanning."
        }
    }
}

struct GLMFlashVisionEngine: VisionNutritionEngine {
    let engineID = "ai_glm"
    let profiles: [GLMProfile]

    init(profiles: [GLMProfile]? = nil) {
        self.profiles = profiles ?? GLMConfig.profiles
    }

    func analyze(imageData: Data, context: MealContext) async throws -> FoodAnalysis {
        guard !profiles.isEmpty else { throw VisionEngineError.notConfigured }
        var lastError: Error = VisionEngineError.badResponse
        for profile in profiles {
            do {
                return try await Self.performCall(endpoint: profile.endpoint, apiKey: profile.apiKey, model: profile.model, imageData: imageData, context: context)
            } catch let error as VisionEngineError {
                lastError = error
                if case .parseFailed = error { throw error }
            } catch let error as URLError {
                lastError = error
            } catch {
                throw error
            }
        }
        throw lastError
    }

    static func performCall(endpoint: URL, apiKey: String, model: String, imageData: Data, context: MealContext) async throws -> FoodAnalysis {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = GLMConfig.timeout
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let b64 = imageData.base64EncodedString()
        let prompt = Self.nutritionPrompt(context: context)
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.2,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(b64)"]],
                    ["type": "text", "text": prompt]
                ]
            ]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw VisionEngineError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw VisionEngineError.http(http.statusCode, bodyText)
        }

        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = payload["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw VisionEngineError.badResponse
        }
        return try Self.parseFoodAnalysis(from: content)
    }

    static func parseFoodAnalysis(from content: String) throws -> FoodAnalysis {
        var text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            text = text.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") else {
            throw VisionEngineError.parseFailed
        }
        let jsonSlice = String(text[start...end])
        guard let jsonData = jsonSlice.data(using: .utf8) else { throw VisionEngineError.parseFailed }
        do {
            return try JSONDecoder().decode(FoodAnalysis.self, from: jsonData)
        } catch {
            throw VisionEngineError.parseFailed
        }
    }

    static func nutritionPrompt(context: MealContext) -> String {
        let note = context.userNote?.isEmpty == false ? " User note: \(context.userNote!). Do not repeat it." : ""
        return """
        You are a nutrition vision analyst. Identify every distinct food item in the photo. For each item estimate the portion in grams and its nutrition (kcal, protein g, carbs g, fat g) using standard USDA-style values for the identified food and portion. Pay special attention to Asian and non-Western dishes, and account for visible cooking oil and sauce. Respond with ONLY valid JSON, no markdown, in exactly this shape:
        {"items":[{"name":"common English food name","portionGrams":150,"kcal":230,"protein":12,"carbs":25,"fat":8,"confidence":0.0,"alternatives":["other possible food"],"cookingMethod":"fried|grilled|steamed|raw|unknown"}],"isMixedDish":false,"overallConfidence":0.0}
        confidence is 0.0-1.0 for each item; overallConfidence reflects the whole photo. isMixedDish is true when cooking oil or sauce calories are likely hidden. Meal type: \(context.mealType). User goal: \(context.goal.rawValue).\(note)
        """
    }
}

struct BYOVisionEngine: VisionNutritionEngine {
    let engineID = "ai_byo"
    let apiKey: String
    let endpoint: URL
    let model: String

    func analyze(imageData: Data, context: MealContext) async throws -> FoodAnalysis {
        try await GLMFlashVisionEngine.performCall(endpoint: endpoint, apiKey: apiKey, model: model, imageData: imageData, context: context)
    }
}
