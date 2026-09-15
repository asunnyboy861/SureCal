import SwiftUI
import SwiftData

@main
struct SureCalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [MealLog.self, FoodEntry.self, WeightLog.self, CalibrationRecord.self])
        }
    }
}
