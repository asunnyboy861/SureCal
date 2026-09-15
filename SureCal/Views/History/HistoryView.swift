import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \MealLog.date, order: .reverse) private var meals: [MealLog]
    @State private var selectedDate = Date()

    private var daysWithMeals: [Date] {
        let calendar = Calendar.current
        let set = Set(meals.map { calendar.startOfDay(for: $0.date) })
        return set.sorted(by: >)
    }

    private var selectedMeals: [MealLog] {
        let start = Calendar.current.startOfDay(for: selectedDate)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return [] }
        return meals.filter { $0.date >= start && $0.date < end }.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                Section {
                    if selectedMeals.isEmpty {
                        Text("No meals logged on this day.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(selectedMeals) { meal in
                            HistoryMealRow(meal: meal)
                        }
                    }
                } header: {
                    let total = selectedMeals.reduce(0) { $0 + $1.totalKcal }
                    Text("Total: \(Int(total)) kcal")
                }
            }
            .navigationTitle("History")
        }
    }
}

struct HistoryMealRow: View {
    let meal: MealLog
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if let photo = meal.photoData, let image = UIImage(data: photo) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 44, height: 44)
                        .overlay(Image(systemName: "fork.knife").font(.caption).foregroundStyle(.secondary))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(meal.items?.first?.name ?? meal.mealType.capitalized)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                }
                Spacer()
                Text("\(Int(meal.totalKcal)) kcal")
                    .font(.subheadline.bold().monospacedDigit())
            }
            if expanded {
                ForEach(Array((meal.items ?? []).enumerated()), id: \.offset) { _, item in
                    HStack {
                        Text(item.name).font(.caption)
                        Spacer()
                        Text("\(Int(item.kcal)) kcal · \(Int(item.grams)) g")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 54)
                }
                HStack(spacing: 8) {
                    Text("Source: \(meal.source)")
                    if meal.wasCorrected {
                        Text("corrected in \(String(format: "%.0f", meal.correctionSeconds))s")
                    }
                    if meal.verifiedBadge {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(Color(red: 0.18, green: 0.36, blue: 1.0))
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.leading, 54)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { expanded.toggle() } }
        .accessibilityLabel("Meal with \(Int(meal.totalKcal)) kilocalories")
        .accessibilityHint("Double tap to show details")
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: meal.date)
    }
}
