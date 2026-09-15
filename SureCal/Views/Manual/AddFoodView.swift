import SwiftUI
import SwiftData

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var query = ""
    @State private var selected: FoodRecord?
    @State private var grams: Double = 100
    @State private var saved = false

    private var results: [FoodRecord] { NutritionLookup.search(query) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let record = selected {
                    detailView(record)
                } else {
                    searchView
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var searchView: some View {
        List {
            Section("Search over \(NutritionLookup.commonFoods.count) common foods (USDA)") {
                TextField("Search food name…", text: $query)
                    .textFieldStyle(.roundedBorder)
                if query.isEmpty {
                    ForEach(NutritionLookup.commonFoods.prefix(8)) { record in
                        row(record)
                    }
                } else {
                    ForEach(results) { record in
                        row(record)
                    }
                    if results.isEmpty {
                        Text("No match — try a simpler name like \"rice\" or \"chicken\".")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section {
                Text("For packaged foods, use the barcode scanner in the top toolbar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func row(_ record: FoodRecord) -> some View {
        Button {
            selected = record
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.name)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text("P \(Int(record.protein))g · C \(Int(record.carbs))g · F \(Int(record.fat))g / 100 g")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(record.kcalPer100g)) kcal")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func detailView(_ record: FoodRecord) -> some View {
        VStack(spacing: 20) {
            Text(record.name)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 24)
            Stepper(value: $grams, in: 10...1500, step: 10) {
                Text("\(Int(grams)) g")
                    .font(.headline.monospacedDigit())
            }
            .padding(.horizontal, 40)
            let nutrition = NutritionLookup.nutrition(forGrams: grams, of: record)
            VStack(spacing: 4) {
                Text("\(Int(nutrition.kcal)) kcal")
                    .font(.largeTitle.bold().monospacedDigit())
                Text("Protein \(Int(nutrition.protein))g · Carbs \(Int(nutrition.carbs))g · Fat \(Int(nutrition.fat))g")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button {
                save(record, nutrition: nutrition)
            } label: {
                Text("Add to Today")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            Spacer()
        }
    }

    private func save(_ record: FoodRecord, nutrition: (kcal: Double, protein: Double, carbs: Double, fat: Double)) {
        guard !saved else { return }
        saved = true
        let meal = MealLog(date: Date(), mealType: mealTypeForNow(), source: "manual")
        let entry = FoodEntry(name: record.name, grams: grams, kcal: nutrition.kcal, protein: nutrition.protein, carbs: nutrition.carbs, fat: nutrition.fat, confidence: 1.0)
        meal.items = [entry]
        entry.meal = meal
        modelContext.insert(meal)
        try? modelContext.save()
        Task { await HealthKitWriter.shared.write(meal: meal) }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }

    private func mealTypeForNow() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "breakfast"
        case 11..<15: return "lunch"
        case 15..<17: return "snack"
        case 17..<22: return "dinner"
        default: return "snack"
        }
    }
}
