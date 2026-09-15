import Foundation

enum TDEECalculator {
    static func bmr(heightCm: Double, weightKg: Double, age: Int, isMale: Bool) -> Double {
        if isMale {
            return 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
        }
        return 10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 161
    }

    static func target(goal: GoalType, heightCm: Double, weightKg: Double, age: Int, isMale: Bool, activityFactor: Double = 1.4) -> Int {
        let tdee = bmr(heightCm: heightCm, weightKg: weightKg, age: age, isMale: isMale) * activityFactor
        switch goal {
        case .lose: return max(1200, Int(tdee - 400))
        case .maintain: return Int(tdee)
        case .gain: return Int(tdee + 400)
        }
    }

    static func macroSplit(forKcal kcal: Int, goal: GoalType) -> (protein: Int, carbs: Int, fat: Int) {
        let proteinPct = goal == .gain ? 0.30 : 0.35
        let fatPct = 0.25
        let carbPct = 1 - proteinPct - fatPct
        return (Int(Double(kcal) * proteinPct / 4), Int(Double(kcal) * carbPct / 4), Int(Double(kcal) * fatPct / 9))
    }
}

struct AdaptiveTDEEEngine {
    static func weeklyAdjustment(weightTrend: [Double], intake: [Double], goal: GoalType, currentTarget: Int) -> Double? {
        let weights = weightTrend.suffix(14)
        let meals = intake.suffix(14)
        guard weights.count >= 5, meals.count >= 5 else { return nil }
        let avgIntake = meals.reduce(0, +) / Double(meals.count)
        let weightDeltaPerDay = (weights.last! - weights.first!) / Double(max(weights.count - 1, 1))
        let realTDEE = avgIntake + weightDeltaPerDay * 7.7
        let target = goal == .lose ? realTDEE - 400 : goal == .gain ? realTDEE + 400 : realTDEE
        let adjustment = target - Double(currentTarget)
        let clamped = max(-200, min(200, adjustment))
        guard abs(clamped) >= 25 else { return nil }
        return clamped
    }

    static func weightedTrend(_ logs: [(date: Date, kg: Double)], days: Int = 14) -> [Double] {
        let calendar = Calendar.current
        let sorted = logs.sorted { $0.date < $1.date }.suffix(days)
        guard !sorted.isEmpty else { return [] }
        var result: [Double] = []
        for dayOffset in (0..<sorted.count) {
            let value = Double(sorted.prefix(dayOffset + 1).suffix(3).map(\.kg).reduce(0, +)) / Double(min(3, dayOffset + 1))
            result.append(value)
        }
        _ = calendar
        return result
    }
}
