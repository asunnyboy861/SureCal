import Foundation
import HealthKit
import Combine

final class HealthKitWriter: ObservableObject {
    static let shared = HealthKitWriter()

    private let store = HKHealthStore()

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    @Published var isAuthorized = false

    func requestAuthorization() async {
        guard Self.isAvailable else { return }
        let writeTypes: Set<HKSampleType> = [
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryFatTotal),
            HKQuantityType(.bodyMass)
        ]
        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.bodyMass)
        ]
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            await MainActor.run { isAuthorized = true }
        } catch {
            await MainActor.run { isAuthorized = false }
        }
    }

    func write(meal: MealLog) async {
        guard Self.isAvailable else { return }
        let kcal = meal.totalKcal
        guard kcal > 0 else { return }
        let gram = HKUnit.gram()
        let samples: [HKSample] = [
            HKQuantitySample(type: HKQuantityType(.dietaryEnergyConsumed), quantity: HKQuantity(unit: .kilocalorie(), doubleValue: kcal), start: meal.date, end: meal.date),
            HKQuantitySample(type: HKQuantityType(.dietaryProtein), quantity: HKQuantity(unit: gram, doubleValue: meal.totalProtein), start: meal.date, end: meal.date),
            HKQuantitySample(type: HKQuantityType(.dietaryCarbohydrates), quantity: HKQuantity(unit: gram, doubleValue: meal.totalCarbs), start: meal.date, end: meal.date),
            HKQuantitySample(type: HKQuantityType(.dietaryFatTotal), quantity: HKQuantity(unit: gram, doubleValue: meal.totalFat), start: meal.date, end: meal.date)
        ]
        try? await store.save(samples)
    }

    func writeBodyMass(_ kg: Double, date: Date = Date()) async {
        guard Self.isAvailable else { return }
        let sample = HKQuantitySample(type: HKQuantityType(.bodyMass), quantity: HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg), start: date, end: date)
        try? await store.save(sample)
    }

    func readTodayActiveEnergy() async -> Double {
        guard Self.isAvailable else { return 0 }
        let type = HKQuantityType(.activeEnergyBurned)
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                let value = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}
