import Foundation
import SwiftData

enum CSVImporter {
    struct ImportSummary: Sendable {
        let imported: Int
        let skipped: Int
    }

    static func parseAndImport(text: String, context: ModelContext) -> ImportSummary {
        var imported = 0
        var skipped = 0
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { return ImportSummary(imported: 0, skipped: lines.count) }

        let header = lines[0].lowercased()
        let delimiter = header.contains("\t") ? "\t" : ","
        let columns = Self.columnMap(header: header.components(separatedBy: delimiter).map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\",\"")).trimmingCharacters(in: CharacterSet(charactersIn: "\"")) })
        guard !columns.isEmpty else { return ImportSummary(imported: 0, skipped: lines.count - 1) }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let altFormatter = DateFormatter()
        altFormatter.dateFormat = "yyyy-MM-dd"

        for line in lines.dropFirst() {
            let fields = line.components(separatedBy: delimiter).map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
            guard let nameIdx = columns["food"], nameIdx < fields.count else { skipped += 1; continue }
            let name = fields[nameIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { skipped += 1; continue }

            var kcal: Double = 0
            var protein: Double = 0
            var carbs: Double = 0
            var fat: Double = 0
            var date = Date()
            if let kcalIdx = columns["kcal"], kcalIdx < fields.count { kcal = Double(fields[kcalIdx].filter { "0123456789.".contains($0) }) ?? 0 }
            if let pIdx = columns["protein"], pIdx < fields.count { protein = Double(fields[pIdx].filter { "0123456789.".contains($0) }) ?? 0 }
            if let cIdx = columns["carbs"], cIdx < fields.count { carbs = Double(fields[cIdx].filter { "0123456789.".contains($0) }) ?? 0 }
            if let fIdx = columns["fat"], fIdx < fields.count { fat = Double(fields[fIdx].filter { "0123456789.".contains($0) }) ?? 0 }
            if let dateIdx = columns["date"], dateIdx < fields.count {
                let raw = fields[dateIdx].trimmingCharacters(in: .whitespaces)
                date = formatter.date(from: raw) ?? altFormatter.date(from: raw) ?? date
            }
            guard kcal > 0 || protein > 0 || carbs > 0 || fat > 0 else { skipped += 1; continue }

            let entry = FoodEntry(name: name, grams: 0, kcal: kcal, protein: protein, carbs: carbs, fat: fat, confidence: 1.0)
            let meal = MealLog(date: date, mealType: Self.mealType(for: date), source: "csv_import")
            meal.items = [entry]
            entry.meal = meal
            context.insert(meal)
            imported += 1
        }
        try? context.save()
        return ImportSummary(imported: imported, skipped: skipped)
    }

    static func exportCSV(meals: [MealLog]) -> String {
        var lines = ["Date,Meal,Food,Kcal,Protein,Carbs,Fat,Source"]
        for meal in meals.sorted(by: { $0.date > $1.date }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            for item in meal.items ?? [] {
                let fields = [formatter.string(from: meal.date), meal.mealType, item.name, String(format: "%.0f", item.kcal), String(format: "%.1f", item.protein), String(format: "%.1f", item.carbs), String(format: "%.1f", item.fat), meal.source]
                lines.append(fields.map { field in field.contains(",") ? "\"\(field)\"" : field }.joined(separator: ","))
            }
        }
        return lines.joined(separator: "\n")
    }

    private static func columnMap(header: [String]) -> [String: Int] {
        var map: [String: Int] = [:]
        for (index, column) in header.enumerated() {
            let c = column.lowercased()
            if c.contains("date") || c.contains("time") { map["date", default: index] = index }
            if c.contains("food") || c.contains("name") || c.contains("dish") { map["food", default: index] = index }
            if c.contains("calorie") || c == "kcal" || c.contains("energy") { map["kcal", default: index] = index }
            if c.contains("protein") { map["protein", default: index] = index }
            if c.contains("carb") { map["carbs", default: index] = index }
            if c.contains("fat") { map["fat", default: index] = index }
        }
        return map
    }

    private static func mealType(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return "breakfast"
        case 11..<15: return "lunch"
        case 15..<17: return "snack"
        case 17..<22: return "dinner"
        default: return "snack"
        }
    }
}
