import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @AppStorage("icloudSyncEnabled") private var icloudSyncEnabled = false

    var body: some View {
        if onboardingComplete {
            TabView {
                TodayView()
                    .tabItem { Label("Today", systemImage: "flame.fill") }
                ProgressPageView()
                    .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                HistoryView()
                    .tabItem { Label("History", systemImage: "calendar") }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            .tint(Color(red: 0.18, green: 0.36, blue: 1.0))
            .task {
                let defaults = UserDefaults.standard
                defaults.set(defaults.integer(forKey: "app.launchCount") + 1, forKey: "app.launchCount")
                await AdaptiveTDEERunner.runWeeklyAdjustmentIfNeeded()
            }
        } else {
            OnboardingView()
                .tint(Color(red: 0.18, green: 0.36, blue: 1.0))
        }
    }
}

enum AdaptiveTDEERunner {
    static func runWeeklyAdjustmentIfNeeded() async {
        let defaults = UserDefaults.standard
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-ww"
        let weekKey = formatter.string(from: Date())
        guard defaults.string(forKey: "tdee.lastWeek") != weekKey else { return }

        let context = ModelContext(SureCalContainer.container)
        let goal = GoalType(rawValue: defaults.string(forKey: "profile.goal") ?? "lose") ?? .lose
        let currentTarget = defaults.integer(forKey: "profile.targetKcal")
        guard currentTarget > 0 else {
            defaults.set(weekKey, forKey: "tdee.lastWeek")
            return
        }

        let weights = try? context.fetch(FetchDescriptor<WeightLog>())
        let meals = try? context.fetch(FetchDescriptor<MealLog>())
        let weightTrend = AdaptiveTDEEEngine.weightedTrend((weights ?? []).map { ($0.date, $0.kilograms) })
        let dailyIntake = Self.dailyIntake(from: meals ?? [])
        guard let adjustment = AdaptiveTDEEEngine.weeklyAdjustment(weightTrend: weightTrend, intake: dailyIntake, goal: goal, currentTarget: currentTarget) else {
            defaults.set(weekKey, forKey: "tdee.lastWeek")
            return
        }
        let newTarget = currentTarget + Int(adjustment)
        defaults.set(newTarget, forKey: "profile.targetKcal")
        var history = defaults.stringArray(forKey: "tdee.history") ?? []
        let deltaFormatter = DateFormatter()
        deltaFormatter.dateFormat = "MMM d"
        history.insert("\(deltaFormatter.string(from: Date())): \(adjustment >= 0 ? "+" : "")\(Int(adjustment)) kcal → \(newTarget) kcal", at: 0)
        defaults.set(Array(history.prefix(20)), forKey: "tdee.history")
        defaults.set(weekKey, forKey: "tdee.lastWeek")
        NotificationHelper.scheduleGoalAdjusted(target: newTarget)
    }

    static func dailyIntake(from meals: [MealLog]) -> [Double] {
        let calendar = Calendar.current
        var byDay: [Date: Double] = [:]
        for meal in meals {
            let day = calendar.startOfDay(for: meal.date)
            byDay[day, default: 0] += meal.totalKcal
        }
        return (0..<14).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: Date())) else { return nil }
            return byDay[day] ?? 0
        }
    }
}

enum NotificationHelper {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func scheduleTrialExpiryReminder(days: Int = 6) {
        let content = UNMutableNotificationContent()
        content.title = "Your SureCal Peak Trial ends tomorrow"
        content.body = "After it ends you'll keep your 3 free monthly scans. Manual logging is always free."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(days) * 24 * 3600, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "trial.expiry", content: content, trigger: trigger))
    }

    static func scheduleGoalAdjusted(target: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Your goal moved to \(target) kcal"
        content.body = "Adjusted from your 14-day weight trend and actual intake. You can always change it in Settings."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "tdee.adjusted", content: content, trigger: trigger))
    }
}

enum SureCalContainer {
    static var container: ModelContainer = {
        let schema = Schema([MealLog.self, FoodEntry.self, WeightLog.self, CalibrationRecord.self])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: UserDefaults.standard.bool(forKey: "icloudSyncEnabled") ? .automatic : .none)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
}
