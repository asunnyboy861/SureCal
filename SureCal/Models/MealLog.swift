import Foundation
import SwiftData

@Model
final class MealLog {
    var date: Date = Date()
    var mealType: String = "lunch"
    var source: String = "ai_glm"
    var wasCorrected: Bool = false
    var correctionSeconds: Double = 0
    var verifiedBadge: Bool = false
    var photoData: Data?
    @Relationship(deleteRule: .cascade, inverse: \FoodEntry.meal)
    var items: [FoodEntry]? = nil

    var totalKcal: Double { items?.reduce(0) { $0 + $1.kcal } ?? 0 }
    var totalProtein: Double { items?.reduce(0) { $0 + $1.protein } ?? 0 }
    var totalCarbs: Double { items?.reduce(0) { $0 + $1.carbs } ?? 0 }
    var totalFat: Double { items?.reduce(0) { $0 + $1.fat } ?? 0 }

    init(date: Date = Date(), mealType: String = "lunch", source: String = "ai_glm") {
        self.date = date
        self.mealType = mealType
        self.source = source
    }
}

@Model
final class FoodEntry {
    var name: String = ""
    var grams: Double = 100
    var kcal: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var confidence: Double = 0.5
    var hiddenOilGrams: Double? = nil
    var alternatives: [String]? = nil
    var meal: MealLog? = nil

    var kcalPerGram: Double { grams > 0 ? kcal / grams : 0 }

    init(name: String, grams: Double, kcal: Double, protein: Double, carbs: Double, fat: Double, confidence: Double) {
        self.name = name
        self.grams = grams
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.confidence = confidence
    }
}

@Model
final class WeightLog {
    var date: Date = Date()
    var kilograms: Double = 70

    init(date: Date = Date(), kilograms: Double) {
        self.date = date
        self.kilograms = kilograms
    }
}

@Model
final class CalibrationRecord {
    var fingerprint: String = ""
    var correctionHistory: [Double] = []
    var averageUserDownwardCorrection: Double = 0
    var hitCount: Int = 0

    init(fingerprint: String) {
        self.fingerprint = fingerprint
    }
}
