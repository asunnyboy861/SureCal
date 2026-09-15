import Foundation

enum ConfidenceBand: Equatable {
    case high
    case medium
    case low

    var colorName: String {
        switch self {
        case .high: return "green"
        case .medium: return "purple"
        case .low: return "orange"
        }
    }
}

enum ScanResultStep: Equatable {
    case highConfidence
    case mediumConfidence
    case quickQuiz
}

struct ConfidenceRouter {
    static func band(_ confidence: Double) -> ConfidenceBand {
        switch confidence {
        case ..<0.50: return .low
        case ..<0.85: return .medium
        default: return .high
        }
    }

    static func route(_ analysis: FoodAnalysis, calibration: CalibrationRecord?) -> ScanResultStep {
        var c = analysis.overallConfidence
        if let cal = calibration {
            c -= cal.averageUserDownwardCorrection
        }
        if analysis.isMixedDish { return .quickQuiz }
        switch c {
        case ..<0.50: return .quickQuiz
        case ..<0.85: return .mediumConfidence
        default: return .highConfidence
        }
    }

    static func fingerprint(for analysis: FoodAnalysis) -> String {
        let names = analysis.items.map { $0.name.lowercased().trimmingCharacters(in: .whitespaces) }.sorted().joined(separator: "|")
        return names
    }
}
