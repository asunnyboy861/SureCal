import Foundation

enum NutritionRDA {
    static let proteinGrams = 50.0
    static let fiberGrams = 28.0
    static let ironMilligrams = 18.0

    static func gapAdvice(protein: Double, fiber: Double, remainingKcal: Int) -> String? {
        if protein < proteinGrams * 0.7 {
            return "Protein is running low — a Greek yogurt or grilled chicken would close the gap."
        }
        if fiber < fiberGrams * 0.6 {
            return "Fiber is a bit short — fruit, beans, or whole grains would help."
        }
        if remainingKcal > 500 {
            return "You have plenty of room today — a balanced meal with protein works well."
        }
        return nil
    }
}
