import Foundation
import Combine

@MainActor
final class DualEngineOrchestrator: ObservableObject {
    static let shared = DualEngineOrchestrator()

    enum Phase: Equatable {
        case idle
        case instant
        case verifying
        case verified
        case conflict
    }

    @Published var phase: Phase = .idle

    struct ScanOutcome: Sendable {
        let analysis: FoodAnalysis
        let verified: Bool
        let conflicted: Bool
        let engineSource: String
    }

    func scan(imageData: Data, context: MealContext) async throws -> ScanOutcome {
        phase = .instant
        let primary = AIRouter.primaryEngine()
        var fast = try await primary.analyze(imageData: imageData, context: context)
        var engineSource = primary.engineID

        let needsVerify = AIRouter.isHardCase(fast) && primary.engineID != "ai_byo"
        guard needsVerify, QuotaManager.shared.canVerify else {
            phase = .idle
            return ScanOutcome(analysis: fast, verified: false, conflicted: false, engineSource: engineSource)
        }

        phase = .verifying
        defer { phase = .idle }
        do {
            let second = try await AIRouter.verifyEngine().analyze(imageData: imageData, context: context)
            QuotaManager.shared.consumeVerify()
            if Self.agree(fast, second) {
                fast.overallConfidence = min(0.99, max(fast.overallConfidence, second.overallConfidence) + 0.1)
                fast.items = fast.items.map { item in
                    var i = item
                    i.confidence = min(0.99, i.confidence + 0.1)
                    return i
                }
                phase = .verified
                return ScanOutcome(analysis: fast, verified: true, conflicted: false, engineSource: engineSource)
            } else {
                if let alt = second.items.first?.name {
                    let merged = [alt] + (fast.items[0].alternatives ?? [])
                    var seen: Set<String> = []
                    fast.items[0].alternatives = merged.filter { seen.insert($0).inserted }
                }
                fast.overallConfidence = min(fast.overallConfidence, 0.5)
                phase = .conflict
                return ScanOutcome(analysis: fast, verified: false, conflicted: true, engineSource: engineSource)
            }
        } catch {
            return ScanOutcome(analysis: fast, verified: false, conflicted: false, engineSource: engineSource)
        }
    }

    nonisolated static func agree(_ a: FoodAnalysis, _ b: FoodAnalysis) -> Bool {
        guard let fa = a.items.first, let fb = b.items.first else { return false }
        let nameA = fa.name.lowercased()
        let nameB = fb.name.lowercased()
        let similar = nameA.contains(nameB) || nameB.contains(nameA) || nameA.similarity(to: nameB) > 0.8
        let portionRatio = abs(fa.portionGrams - fb.portionGrams) / max(max(fa.portionGrams, fb.portionGrams), 1)
        return similar && portionRatio < 0.3
    }
}

extension String {
    func similarity(to other: String) -> Double {
        let a = Array(self)
        let b = Array(other)
        guard !a.isEmpty || !b.isEmpty else { return 1.0 }
        let dist = levenshtein(a, b)
        return 1.0 - Double(dist) / Double(max(a.count, b.count))
    }

    private func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        var matrix = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in 0...a.count { matrix[i][0] = i }
        for j in 0...b.count { matrix[0][j] = j }
        for i in 1...a.count {
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                matrix[i][j] = Swift.min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + cost)
            }
        }
        return matrix[a.count][b.count]
    }
}


