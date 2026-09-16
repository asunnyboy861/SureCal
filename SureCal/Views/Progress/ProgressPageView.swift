import SwiftUI
import SwiftData
import Charts

struct ProgressPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightLog.date, order: .reverse) private var weights: [WeightLog]
    @Query(sort: \MealLog.date, order: .reverse) private var meals: [MealLog]
    @AppStorage("profile.targetKcal") private var targetKcal = 2000
    @AppStorage("profile.goal") private var goalRaw = GoalType.lose.rawValue
    @State private var showAddWeight = false
    @State private var newWeight: Double = 70

    private var trend: [(date: Date, kg: Double)] {
        weights.map { ($0.date, $0.kilograms) }
    }

    private var todayKcal: Double {
        let start = Calendar.current.startOfDay(for: Date())
        return meals.filter { $0.date >= start }.reduce(0) { $0 + $1.totalKcal }
    }

    private var todayMacros: (protein: Double, carbs: Double, fat: Double) {
        let start = Calendar.current.startOfDay(for: Date())
        let today = meals.filter { $0.date >= start }
        return (today.reduce(0) { $0 + $1.totalProtein }, today.reduce(0) { $0 + $1.totalCarbs }, today.reduce(0) { $0 + $1.totalFat })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    weightCard
                    goalAdjustmentCard
                    gapAdviceCard
                }
                .padding()
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
            .sheet(isPresented: $showAddWeight) { addWeightSheet }
        }
    }

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("14-Day Weight Trend")
                    .font(.headline)
                Spacer()
                Button {
                    newWeight = weights.first?.kilograms ?? 70
                    showAddWeight = true
                } label: {
                    Label("Log weight", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
                .accessibilityLabel("Log your weight")
            }
            if trend.count >= 2 {
                Chart(trend.sorted { $0.date < $1.date }, id: \.date) { point in
                    LineMark(x: .value("Date", point.date), y: .value("kg", point.kg))
                        .foregroundStyle(Color(red: 0.18, green: 0.36, blue: 1.0))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Date", point.date), y: .value("kg", point.kg))
                        .foregroundStyle(Color(red: 0.18, green: 0.36, blue: 1.0))
                }
                .frame(height: 180)
            } else {
                Text("Log your weight for a few days to see your trend — single-day swings are normal.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
            }
            if let latest = weights.first {
                Text("Latest: \(String(format: "%.1f", latest.kilograms)) kg")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var goalAdjustmentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Goal Adjustments")
                .font(.headline)
            let history = UserDefaults.standard.stringArray(forKey: "tdee.history") ?? []
            if history.isEmpty {
                Text("After a week of tracking, SureCal nudges your target based on your real weight trend — never daily jitter.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(history.prefix(6), id: \.self) { entry in
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(Color(red: 0.18, green: 0.36, blue: 1.0))
                        Text(entry)
                            .font(.subheadline.monospacedDigit())
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var gapAdviceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Nutrition Notes")
                .font(.headline)
            let advice = NutritionRDA.gapAdvice(protein: todayMacros.protein, fiber: todayMacros.carbs, remainingKcal: max(0, targetKcal - Int(todayKcal)))
            if let advice {
                Label(advice, systemImage: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            } else {
                Label("You're on a balanced track today.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
            HStack(spacing: 16) {
                macroChip("Protein", todayMacros.protein, .mint)
                macroChip("Carbs", todayMacros.carbs, .yellow)
                macroChip("Fat", todayMacros.fat, .pink)
            }
            Text("General wellness information, not medical advice.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func macroChip(_ label: String, _ value: Double, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label) \(Int(value))g")
                .font(.caption.monospacedDigit())
        }
    }

    private var addWeightSheet: some View {
        NavigationStack {
            Form {
                Section("Today's weight") {
                    LabeledContent("Weight") {
                        TextField("kg", value: $newWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Button {
                    let log = WeightLog(date: Date(), kilograms: newWeight)
                    modelContext.insert(log)
                    try? modelContext.save()
                    Task { await HealthKitWriter.shared.writeBodyMass(newWeight) }
                    showAddWeight = false
                } label: {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
