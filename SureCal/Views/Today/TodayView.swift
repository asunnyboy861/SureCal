import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealLog.date, order: .reverse) private var meals: [MealLog]
    @StateObject private var quota = QuotaManager.shared
    @StateObject private var orchestrator = DualEngineOrchestrator.shared
    @AppStorage("profile.targetKcal") private var targetKcal = 2000
    @State private var showCamera = false
    @State private var showPaywall = false
    @State private var showBarcode = false
    @State private var showManual = false
    @State private var activeEnergy: Double = 0

    private var todayMeals: [MealLog] {
        let start = Calendar.current.startOfDay(for: Date())
        return meals.filter { $0.date >= start }
    }

    private var consumed: Double { todayMeals.reduce(0) { $0 + $1.totalKcal } }
    private var protein: Double { todayMeals.reduce(0) { $0 + $1.totalProtein } }
    private var carbs: Double { todayMeals.reduce(0) { $0 + $1.totalCarbs } }
    private var fat: Double { todayMeals.reduce(0) { $0 + $1.totalFat } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    CalorieRing(consumed: consumed, target: Double(targetKcal), protein: protein, carbs: carbs, fat: fat, proteinTarget: Double(targetKcal / 3), carbsTarget: Double(targetKcal / 3), fatTarget: Double(targetKcal / 4))
                        .padding(.top, 8)
                    shutterSection
                    mealCards
                }
                .padding(.horizontal)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(todayTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button { showBarcode = true } label: { Image(systemName: "barcode.viewfinder") }
                            .accessibilityLabel("Scan a barcode")
                        Button { showManual = true } label: { Image(systemName: "plus.square") }
                            .accessibilityLabel("Add food manually")
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) { CameraScanView() }
            .sheet(isPresented: $showBarcode) { BarcodeScannerView() }
            .sheet(isPresented: $showManual) { AddFoodView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .task {
                activeEnergy = await HealthKitWriter.shared.readTodayActiveEnergy()
                HealthKitWriter.shared.requestAuthorizationIfSecondLaunch()
            }
        }
    }

    private var todayTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private var header: some View {
        HStack {
            if activeEnergy > 0 {
                Label("\(Int(activeEnergy)) kcal active", systemImage: "figure.run")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var shutterSection: some View {
        VStack(spacing: 10) {
            ShutterButton {
                if quota.canScan {
                    showCamera = true
                } else {
                    showPaywall = true
                }
            }
            scanDots
        }
        .padding(.vertical, 4)
    }

    private var scanDots: some View {
        Group {
            if SubscriptionManager.shared.isPro {
                Label("Pro — unlimited scans", systemImage: "infinity")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.18, green: 0.36, blue: 1.0))
            } else if quota.remainingFreeScans > 0 {
                HStack(spacing: 6) {
                    ForEach(0..<QuotaManager.monthlyFreeScans, id: \.self) { index in
                        Circle()
                            .fill(index < quota.remainingFreeScans ? Color(red: 0.18, green: 0.36, blue: 1.0) : Color(.systemGray3))
                            .frame(width: 8, height: 8)
                    }
                    Text("\(quota.remainingFreeScans) free scans left this month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Text("Upgrade for unlimited scans")
                        .font(.caption.bold())
                        .foregroundStyle(Color(red: 0.18, green: 0.36, blue: 1.0))
                }
                .accessibilityLabel("Upgrade for unlimited scans")
            }
        }
        .animation(.easeInOut, value: quota.remainingFreeScans)
    }

    private var mealCards: some View {
        Group {
            if todayMeals.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("Snap your first meal — it takes 5 seconds.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(todayMeals) { meal in
                        TodayMealCard(meal: meal)
                    }
                }
            }
        }
    }
}

struct TodayMealCard: View {
    let meal: MealLog

    var body: some View {
        HStack(spacing: 12) {
            if let photo = meal.photoData, let image = UIImage(data: photo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: "fork.knife").foregroundStyle(.secondary))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(meal.items?.first?.name ?? meal.mealType.capitalized)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(meal.mealType.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if meal.verifiedBadge { DualEngineBadge() }
                    else if (meal.items?.first?.confidence).map({ ConfidenceRouter.band($0) }) == .low {
                        ConfidenceBadge(confidence: meal.items?.first?.confidence ?? 0.4)
                    }
                }
            }
            Spacer()
            Text("\(Int(meal.totalKcal))")
                .font(.title3.bold().monospacedDigit())
            Text("kcal")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

extension HealthKitWriter {
    func requestAuthorizationIfSecondLaunch() {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: "app.launchCount")
        if count >= 2, !isAuthorized {
            Task { await requestAuthorization() }
        }
    }
}
