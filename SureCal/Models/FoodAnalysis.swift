import Foundation

struct FoodAnalysis: Codable, Sendable, Equatable {
    var items: [FoodAnalysisItem]
    var isMixedDish: Bool
    var overallConfidence: Double
}

struct FoodAnalysisItem: Codable, Sendable, Equatable {
    var name: String
    var portionGrams: Double
    var kcal: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var confidence: Double
    var alternatives: [String]?
    var cookingMethod: String?
    var hiddenOilGrams: Double? = nil

    enum CodingKeys: String, CodingKey {
        case name, portionGrams, kcal, protein, carbs, fat, confidence, alternatives, cookingMethod
    }

    init(name: String, portionGrams: Double, kcal: Double, protein: Double, carbs: Double, fat: Double, confidence: Double, alternatives: [String]? = nil, cookingMethod: String? = nil) {
        self.name = name
        self.portionGrams = portionGrams
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.confidence = confidence
        self.alternatives = alternatives
        self.cookingMethod = cookingMethod
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Food"
        portionGrams = Self.flexibleDouble(c, .portionGrams) ?? 100
        kcal = Self.flexibleDouble(c, .kcal) ?? 0
        protein = Self.flexibleDouble(c, .protein) ?? 0
        carbs = Self.flexibleDouble(c, .carbs) ?? 0
        fat = Self.flexibleDouble(c, .fat) ?? 0
        confidence = Self.flexibleDouble(c, .confidence) ?? 0.5
        alternatives = try? c.decodeIfPresent([String].self, forKey: .alternatives)
        cookingMethod = try? c.decodeIfPresent(String.self, forKey: .cookingMethod)
    }

    private static func flexibleDouble(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Double? {
        if let d = try? c.decodeIfPresent(Double.self, forKey: key) { return d }
        if let i = try? c.decodeIfPresent(Int.self, forKey: key) { return Double(i) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) { return Double(s.filter { "0123456789.-".contains($0) }) }
        return nil
    }
}

struct MealContext: Sendable {
    var mealType: String
    var goal: GoalType
    var userNote: String?
}

enum GoalType: String, Codable, CaseIterable {
    case lose, maintain, gain
}
