import XCTest
import SwiftData
@testable import SureCal

final class SureCalLogicTests: XCTestCase {

    func testConfidenceBandBoundaries() {
        XCTAssertEqual(ConfidenceRouter.band(0.95), .high)
        XCTAssertEqual(ConfidenceRouter.band(0.85), .high)
        XCTAssertEqual(ConfidenceRouter.band(0.7), .medium)
        XCTAssertEqual(ConfidenceRouter.band(0.5), .medium)
        XCTAssertEqual(ConfidenceRouter.band(0.49), .low)
        XCTAssertEqual(ConfidenceRouter.band(0.1), .low)
    }

    func testConfidenceRouterRouting() {
        let high = FoodAnalysis(items: [FoodAnalysisItem(name: "Rice", portionGrams: 200, kcal: 260, protein: 5, carbs: 56, fat: 0.6, confidence: 0.9)], isMixedDish: false, overallConfidence: 0.9)
        XCTAssertEqual(ConfidenceRouter.route(high, calibration: nil), .highConfidence)

        let mixed = FoodAnalysis(items: [FoodAnalysisItem(name: "Stir-fry", portionGrams: 300, kcal: 450, protein: 20, carbs: 30, fat: 25, confidence: 0.6)], isMixedDish: true, overallConfidence: 0.9)
        XCTAssertEqual(ConfidenceRouter.route(mixed, calibration: nil), .quickQuiz)

        let low = FoodAnalysis(items: [FoodAnalysisItem(name: "Dish", portionGrams: 200, kcal: 300, protein: 10, carbs: 20, fat: 10, confidence: 0.3)], isMixedDish: false, overallConfidence: 0.3)
        XCTAssertEqual(ConfidenceRouter.route(low, calibration: nil), .quickQuiz)
    }

    func testCalibrationLowersBand() {
        let borderline = FoodAnalysis(items: [FoodAnalysisItem(name: "Noodles", portionGrams: 300, kcal: 500, protein: 15, carbs: 70, fat: 12, confidence: 0.8)], isMixedDish: false, overallConfidence: 0.87)
        let calibration = CalibrationRecord(fingerprint: "noodles")
        calibration.averageUserDownwardCorrection = 0.05
        XCTAssertEqual(ConfidenceRouter.route(borderline, calibration: calibration), .mediumConfidence)
    }

    func testDualEngineAgreement() {
        let a = FoodAnalysis(items: [FoodAnalysisItem(name: "Grilled chicken breast", portionGrams: 200, kcal: 330, protein: 62, carbs: 0, fat: 7, confidence: 0.8)], isMixedDish: false, overallConfidence: 0.8)
        let b = FoodAnalysis(items: [FoodAnalysisItem(name: "grilled chicken", portionGrams: 210, kcal: 350, protein: 65, carbs: 0, fat: 8, confidence: 0.85)], isMixedDish: false, overallConfidence: 0.85)
        XCTAssertTrue(DualEngineOrchestrator.agree(a, b))

        let c = FoodAnalysis(items: [FoodAnalysisItem(name: "Beef pho", portionGrams: 600, kcal: 500, protein: 30, carbs: 60, fat: 12, confidence: 0.6)], isMixedDish: true, overallConfidence: 0.6)
        let d = FoodAnalysis(items: [FoodAnalysisItem(name: "Pork ramen", portionGrams: 500, kcal: 700, protein: 28, carbs: 80, fat: 20, confidence: 0.7)], isMixedDish: true, overallConfidence: 0.7)
        XCTAssertFalse(DualEngineOrchestrator.agree(c, d))
    }

    func testTDEECalculator() {
        let bmr = TDEECalculator.bmr(heightCm: 175, weightKg: 75, age: 30, isMale: true)
        XCTAssertEqual(bmr, 1698.75, accuracy: 1)
        let target = TDEECalculator.target(goal: .lose, heightCm: 175, weightKg: 75, age: 30, isMale: true)
        XCTAssertEqual(target, Int(1698.75 * 1.4 - 400))
    }

    func testAdaptiveTDEEClamping() {
        let weights: [(date: Date, kg: Double)] = (0..<14).map { offset in
            (Date().addingTimeInterval(Double(-offset) * 86400), 75 - Double(offset) * 0.1)
        }
        let intake = Array(repeating: 2500.0, count: 14)
        let adjustment = AdaptiveTDEEEngine.weeklyAdjustment(weightTrend: weights.map(\.kg), intake: intake, goal: .lose, currentTarget: 2000)
        XCTAssertNotNil(adjustment)
        if let adjustment {
            XCTAssertLessThanOrEqual(abs(adjustment), 200)
        }
    }

    func testGLMParseHandlesFencedJSON() throws {
        let content = """
        ```json
        {"items":[{"name":"tomato","portionGrams":120,"kcal":22,"protein":1,"carbs":4.7,"fat":0.2,"confidence":0.9}],"isMixedDish":false,"overallConfidence":0.9}
        ```
        """
        let analysis = try GLMFlashVisionEngine.parseFoodAnalysis(from: content)
        XCTAssertEqual(analysis.items.count, 1)
        XCTAssertEqual(analysis.items[0].name, "tomato")
        XCTAssertEqual(analysis.overallConfidence, 0.9, accuracy: 0.001)
    }

    func testFoodAnalysisFlexibleDecoding() throws {
        let json = """
        {"items":[{"name":"eggs","portionGrams":"150","kcal":"230","protein":19,"carbs":1,"fat":16,"confidence":0.88}],"isMixedDish":false,"overallConfidence":0.88}
        """
        let analysis = try JSONDecoder().decode(FoodAnalysis.self, from: Data(json.utf8))
        XCTAssertEqual(analysis.items[0].portionGrams, 150)
        XCTAssertEqual(analysis.items[0].kcal, 230)
    }

    func testCSVImport() {
        let csv = """
        Date,Food,Kcal,Protein,Carbs,Fat
        2026-09-01 12:30,Chicken Rice,520,32,60,12
        2026-09-02 08:00,Oatmeal,150,5,27,3
        """
        let container = try! ModelContainer(for: MealLog.self, FoodEntry.self, WeightLog.self, CalibrationRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let summary = CSVImporter.parseAndImport(text: csv, context: context)
        XCTAssertEqual(summary.imported, 2)
        let meals = try! context.fetch(FetchDescriptor<MealLog>())
        XCTAssertEqual(meals.count, 2)
    }

    func testFingerprintIsStableAndSorted() {
        let a = FoodAnalysis(items: [
            FoodAnalysisItem(name: "Rice", portionGrams: 200, kcal: 260, protein: 5, carbs: 56, fat: 1, confidence: 0.9),
            FoodAnalysisItem(name: "Chicken", portionGrams: 150, kcal: 250, protein: 46, carbs: 0, fat: 5, confidence: 0.9)
        ], isMixedDish: false, overallConfidence: 0.9)
        let b = FoodAnalysis(items: [
            FoodAnalysisItem(name: "chicken ", portionGrams: 150, kcal: 250, protein: 46, carbs: 0, fat: 5, confidence: 0.9),
            FoodAnalysisItem(name: "rice", portionGrams: 200, kcal: 260, protein: 5, carbs: 56, fat: 1, confidence: 0.9)
        ], isMixedDish: false, overallConfidence: 0.9)
        XCTAssertEqual(ConfidenceRouter.fingerprint(for: a), ConfidenceRouter.fingerprint(for: b))
    }
}
